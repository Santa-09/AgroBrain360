from uuid import UUID

from fastapi import APIRouter, Body, Depends, Query
from sqlalchemy.orm import Session

from database import crud
from database.connection import get_db
from services import response_service
from utils.auth import get_current_user_id

router = APIRouter(prefix="/sync", tags=["Offline Sync"])


def _persist_record(db: Session, user_id: UUID, module: str, payload: dict) -> None:
    if module == "crop":
        crud.create_crop_scan(db, user_id=user_id, **payload)
    elif module == "livestock":
        crud.create_livestock_rec(db, user_id=user_id, **payload)
    elif module in {"fhi", "health"}:
        crud.create_health_index(db, user_id=user_id, **payload)
    elif module == "profile_feedback":
        crud.update_profile_feedback(
            db,
            user_id=user_id,
            rating=int(payload["rating"]),
            feedback=payload.get("feedback"),
        )
    else:
        raise ValueError(f"Unsupported module: {module}")


def _parse_user_id(value: object) -> UUID | None:
    if value in (None, "", 0, "0"):
        return None
    try:
        return UUID(str(value))
    except (TypeError, ValueError):
        return None


def _extract_history_record(body: dict) -> dict:
    payload = body.get("payload")
    if isinstance(payload, dict):
        record = dict(payload)
    else:
        record = dict(body)

    record.setdefault("scan_key", record.get("_key"))
    record.setdefault("type", record.get("module"))
    return record


def _save_history_record(db: Session, user_id: UUID, body: dict) -> bool:
    record = _extract_history_record(body)
    scan_key = str(record.get("scan_key") or "").strip()
    title = str(record.get("title") or "").strip()
    record_type = str(record.get("type") or "").strip().lower()
    if not scan_key or not title or not record_type:
        return False

    crud.create_or_update_scan_history(
        db,
        user_id=user_id,
        scan_key=scan_key,
        type=record_type,
        title=title,
        result=record.get("result"),
        source=record.get("source"),
        ts=record.get("ts"),
        payload=record,
    )
    return True


def _serialize_history_item(item) -> dict:
    payload = dict(item.payload or {})
    payload.update(
        {
            "scan_key": item.scan_key,
            "_key": item.scan_key,
            "user_id": str(item.user_id),
            "type": item.type,
            "title": item.title,
            "result": item.result,
            "source": item.source,
            "ts": item.ts.isoformat() if item.ts else item.created_at.isoformat(),
        }
    )
    return payload


@router.post("")
@router.post("/")
def sync_offline_records(
    body: dict | None = Body(default=None),
    db: Session = Depends(get_db),
    user_id=Depends(get_current_user_id),
):
    if body:
        records = body.get("records")
        if isinstance(records, list):
            synced = 0
            for record in records:
                try:
                    record_user_id = _parse_user_id(record.get("user_id")) or user_id
                    if record_user_id != user_id:
                        continue
                    _persist_record(db, record_user_id, record["module"], record["payload"])
                    synced += 1
                except Exception:
                    continue
            return response_service.build({"synced": synced, "total": len(records)})

        try:
            record_user_id = _parse_user_id(body.get("user_id")) or user_id
            if record_user_id != user_id:
                return response_service.build({"synced": 0, "total": 1})
            _persist_record(db, record_user_id, body["module"], body["payload"])
            return response_service.build({"synced": 1, "total": 1})
        except Exception:
            return response_service.build({"synced": 0, "total": 1})

    pending = crud.get_pending_sync_items(db, user_id)
    synced = 0
    for item in pending:
        try:
            _persist_record(db, user_id, item.module, item.payload)
            crud.mark_synced(db, item.id)
            synced += 1
        except Exception:
            continue
    return response_service.build({"synced": synced, "total": len(pending)})


@router.post("/history")
def sync_history_records(
    body: dict | None = Body(default=None),
    db: Session = Depends(get_db),
    user_id=Depends(get_current_user_id),
):
    if not body:
        return response_service.build({"synced": 0, "total": 0})

    records = body.get("records")
    if isinstance(records, list):
        synced = 0
        for record in records:
            if not isinstance(record, dict):
                continue
            try:
                record_user_id = _parse_user_id(record.get("user_id")) or user_id
                if record_user_id != user_id:
                    continue
                if _save_history_record(db, record_user_id, record):
                    synced += 1
            except Exception:
                continue
        return response_service.build({"synced": synced, "total": len(records)})

    try:
        record_user_id = _parse_user_id(body.get("user_id")) or user_id
        if record_user_id != user_id:
            return response_service.build({"synced": 0, "total": 1})
        synced = 1 if _save_history_record(db, record_user_id, body) else 0
        return response_service.build({"synced": synced, "total": 1})
    except Exception:
        return response_service.build({"synced": 0, "total": 1})


@router.get("/history")
def get_history_records(
    limit: int = Query(default=200, ge=1, le=500),
    db: Session = Depends(get_db),
    user_id=Depends(get_current_user_id),
):
    items = crud.get_user_scan_history(db, user_id, limit=limit)
    return response_service.build(
        {
            "items": [_serialize_history_item(item) for item in items],
            "total": len(items),
        }
    )
