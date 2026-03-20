import time
from functools import lru_cache
from uuid import UUID

import httpx
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import jwk, jwt
from jose.utils import base64url_decode

from config.settings import settings

bearer_scheme = HTTPBearer(auto_error=False)


class AuthError(Exception):
    pass


@lru_cache(maxsize=1)
def _jwks_url() -> str:
    return f"{settings.SUPABASE_URL.rstrip('/')}/auth/v1/.well-known/jwks.json"


_jwks_cache: dict[str, object] = {"fetched_at": 0.0, "keys": None}


def _fetch_jwks() -> dict:
    now = time.time()
    cached = _jwks_cache.get("keys")
    fetched_at = float(_jwks_cache.get("fetched_at") or 0.0)
    if isinstance(cached, dict) and now - fetched_at < 3600:
        return cached

    response = httpx.get(_jwks_url(), timeout=10.0)
    response.raise_for_status()
    jwks = response.json()
    _jwks_cache["keys"] = jwks
    _jwks_cache["fetched_at"] = now
    return jwks


def _verify_supabase_token(token: str) -> dict:
    try:
        header = jwt.get_unverified_header(token)
        claims = jwt.get_unverified_claims(token)
    except Exception as exc:
        raise AuthError("Malformed access token") from exc

    jwks = _fetch_jwks()
    keys = jwks.get("keys", [])
    key_data = next((item for item in keys if item.get("kid") == header.get("kid")), None)
    if key_data is None:
        raise AuthError("Signing key not found")

    message, encoded_signature = token.rsplit(".", 1)
    decoded_signature = base64url_decode(encoded_signature.encode("utf-8"))
    public_key = jwk.construct(key_data)
    if not public_key.verify(message.encode("utf-8"), decoded_signature):
        raise AuthError("Invalid token signature")

    expires_at = claims.get("exp")
    if expires_at is None or float(expires_at) < time.time():
        raise AuthError("Access token expired")

    expected_issuer = f"{settings.SUPABASE_URL.rstrip('/')}/auth/v1"
    if claims.get("iss") != expected_issuer:
        raise AuthError("Unexpected token issuer")

    audience = claims.get("aud")
    valid_audiences = {settings.SUPABASE_JWT_AUDIENCE, "authenticated"}
    if isinstance(audience, list):
        if not valid_audiences.intersection(set(audience)):
            raise AuthError("Unexpected token audience")
    elif audience not in valid_audiences:
        raise AuthError("Unexpected token audience")

    return claims


def _extract_user_id(claims: dict) -> UUID:
    subject = claims.get("sub")
    if not subject:
        raise AuthError("Missing subject claim")
    try:
        return UUID(str(subject))
    except ValueError as exc:
        raise AuthError("Invalid subject claim") from exc


def get_current_user_id(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
) -> UUID:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing bearer token",
        )

    try:
        claims = _verify_supabase_token(credentials.credentials)
        return _extract_user_id(claims)
    except (AuthError, httpx.HTTPError) as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(exc),
        ) from exc


def get_optional_user_id(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> UUID | None:
    if credentials is None:
        return None
    if credentials.scheme.lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authorization scheme",
        )

    try:
        claims = _verify_supabase_token(credentials.credentials)
        return _extract_user_id(claims)
    except (AuthError, httpx.HTTPError) as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(exc),
        ) from exc
