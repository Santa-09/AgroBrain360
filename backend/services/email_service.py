import smtplib
from email.message import EmailMessage

from config.settings import settings


def send_password_reset_otp_email(*, to_email: str, otp: str) -> None:
    if not settings.SMTP_HOST or not settings.SMTP_USERNAME or not settings.SMTP_PASSWORD:
        raise RuntimeError("SMTP is not configured")

    msg = EmailMessage()
    msg["Subject"] = "AgroBrain 360 password reset OTP"
    msg["From"] = settings.SMTP_FROM_EMAIL or settings.SMTP_USERNAME
    msg["To"] = to_email
    msg.set_content(
        f"Your AgroBrain 360 password reset OTP is {otp}. "
        f"It expires in {settings.OTP_EXPIRY_MINUTES} minutes."
    )

    with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT, timeout=20) as server:
        if settings.SMTP_USE_TLS:
            server.starttls()
        server.login(settings.SMTP_USERNAME, settings.SMTP_PASSWORD)
        server.send_message(msg)
