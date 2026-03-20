# backend/services/farm_memory_service.py
# ─────────────────────────────────────────────────────────────
# Tracks farmer scan history to learn patterns and generate
# seasonal predictions and personalized recommendations.
# ─────────────────────────────────────────────────────────────

import json
import logging
from collections import Counter
from datetime import datetime
from uuid import UUID
from sqlalchemy.orm import Session
from database.models import CropScan, LivestockRec, HealthIndex
from database.crud import get_user_crop_scans

log = logging.getLogger(__name__)


# ── Pattern analysis ──────────────────────────────────────────

def get_disease_frequency(db: Session, user_id: UUID | str) -> dict:
    """
    Returns the most frequently detected diseases for a farmer.
    Used to warn about recurring issues before the season starts.
    """
    scans    = get_user_crop_scans(db, user_id, limit=50)
    diseases = [s.disease for s in scans if s.disease]
    counts   = Counter(diseases)
    ranked   = [{"disease": d, "count": c}
                for d, c in counts.most_common(5)]
    return {
        "user_id":          user_id,
        "total_scans":      len(scans),
        "top_diseases":     ranked,
        "most_common":      ranked[0]["disease"] if ranked else None,
    }


def get_health_trend(db: Session, user_id: UUID | str) -> dict:
    """
    Returns FHI score trend over last 5 records.
    Tells farmer if farm health is improving or declining.
    """
    records = (
        db.query(HealthIndex)
          .filter(HealthIndex.user_id == user_id)
          .order_by(HealthIndex.created_at.desc())
          .limit(5)
          .all()
    )

    if not records:
        return {"trend": "no_data", "scores": [], "message": "No health records found."}

    scores = [r.fhi_score for r in records]
    scores.reverse()   # oldest → newest

    if len(scores) >= 2:
        delta = scores[-1] - scores[0]
        if delta > 5:
            trend = "improving"
        elif delta < -5:
            trend = "declining"
        else:
            trend = "stable"
    else:
        trend = "stable"

    return {
        "trend":   trend,
        "scores":  scores,
        "latest":  scores[-1],
        "message": _trend_message(trend, scores[-1]),
    }


def _trend_message(trend: str, latest: float) -> str:
    if trend == "improving":
        return f"Your farm health is improving. Current score: {latest:.1f}/100. Keep it up!"
    elif trend == "declining":
        return f"Farm health is declining. Current score: {latest:.1f}/100. Review soil and water inputs."
    else:
        return f"Farm health is stable at {latest:.1f}/100."


def get_seasonal_predictions(db: Session, user_id: UUID | str) -> dict:
    """
    Based on past disease history and current month,
    predicts likely diseases for this season.
    """
    month    = datetime.now().month
    scans    = get_user_crop_scans(db, user_id, limit=100)
    diseases = [s.disease for s in scans if s.disease]
    counts   = Counter(diseases)

    # Seasonal risk map — month → high-risk diseases
    SEASONAL_RISK = {
        # Kharif season (Jun–Oct) — rice, maize, soybean
        6:  ["Rice___Leaf_Blast", "Tomato___Late_blight"],
        7:  ["Rice___Leaf_Blast", "Potato___Late_blight", "Tomato___Early_blight"],
        8:  ["Rice___Leaf_Blast", "Tomato___Late_blight", "Pepper,_bell___Bacterial_spot"],
        9:  ["Tomato___Early_blight", "Potato___Late_blight"],
        10: ["Tomato___Early_blight", "Pepper,_bell___Bacterial_spot"],
        # Rabi season (Nov–Mar) — wheat, potato, mustard
        11: ["Potato___Late_blight", "Tomato___Early_blight"],
        12: ["Potato___Late_blight"],
        1:  ["Potato___Late_blight"],
        2:  ["Potato___Late_blight", "Tomato___Early_blight"],
        3:  ["Tomato___Early_blight", "Rice___Leaf_Blast"],
        # Summer (Apr–May)
        4:  ["Tomato___Early_blight", "Pepper,_bell___Bacterial_spot"],
        5:  ["Rice___Leaf_Blast", "Tomato___Late_blight"],
    }

    seasonal = SEASONAL_RISK.get(month, [])

    # Cross-reference with farmer's own history
    personal_risk = [d for d, _ in counts.most_common(3)]
    combined      = list(dict.fromkeys(seasonal + personal_risk))[:5]

    return {
        "month":             month,
        "seasonal_risks":    seasonal,
        "personal_history":  personal_risk,
        "watch_out_for":     combined,
        "advice":            _seasonal_advice(month),
    }


def _seasonal_advice(month: int) -> str:
    if month in (6, 7, 8, 9, 10):
        return ("Kharif season: Monitor rice for Leaf Blast after rain. "
                "Keep fields well-drained.")
    elif month in (11, 12, 1, 2, 3):
        return ("Rabi season: Watch potato and tomato for Late Blight "
                "in cool humid conditions.")
    else:
        return ("Summer: Ensure adequate irrigation. Watch for "
                "bacterial infections in pepper and tomato.")


def get_farm_summary(db: Session, user_id: UUID | str) -> dict:
    """
    Full farm memory summary — combines disease frequency,
    health trend, and seasonal predictions into one response.
    """
    disease_freq  = get_disease_frequency(db, user_id)
    health_trend  = get_health_trend(db, user_id)
    seasonal_pred = get_seasonal_predictions(db, user_id)

    return {
        "user_id":            user_id,
        "disease_frequency":  disease_freq,
        "health_trend":       health_trend,
        "seasonal_prediction": seasonal_pred,
    }
