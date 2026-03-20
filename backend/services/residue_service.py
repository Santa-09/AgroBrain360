import json
import logging
import os
from functools import lru_cache

log = logging.getLogger(__name__)

BASE_DIR = os.path.dirname(__file__)
PROJECT_ROOT = os.path.normpath(os.path.join(BASE_DIR, "..", ".."))
JSON_CANDIDATES = [
    os.path.join(BASE_DIR, "..", "ml_models", "residue_recommendations.json"),
    os.path.join(PROJECT_ROOT, "ml_models", "residue_recommendations.json"),
]


def _resolve_json_path() -> str | None:
    for path in JSON_CANDIDATES:
        normalized = os.path.normpath(path)
        if os.path.exists(normalized):
            return normalized
    return None


@lru_cache(maxsize=1)
def _load_data() -> dict:
    path = _resolve_json_path()
    if not path:
        log.warning("residue_recommendations.json not found; residue responses will be empty")
        return {"crops": {}, "government_schemes": []}

    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def get_supported_crops() -> list[str]:
    return list(_load_data()["crops"].keys())


def get_recommendations(crop: str) -> dict:
    data = _load_data()
    crop = crop.lower().strip()
    crops = data["crops"]

    if crop not in crops:
        return {
            "found": False,
            "message": f"No data for '{crop}'. Supported: {list(crops.keys())}",
            "supported_crops": list(crops.keys()),
        }

    entry = crops[crop]
    return {
        "found": True,
        "crop": crop,
        "residue_type": entry["residue_type"],
        "quantity_per_acre": entry["quantity_per_acre"],
        "options": entry["options"],
        "government_schemes": data.get("government_schemes", []),
    }


def get_option_detail(crop: str, option_id: str) -> dict:
    data = _load_data()
    crop = crop.lower().strip()
    crops = data["crops"]

    if crop not in crops:
        return {"found": False, "message": f"Crop '{crop}' not found"}

    for option in crops[crop]["options"]:
        if option["id"] == option_id:
            return {"found": True, "crop": crop, "option": option}

    return {"found": False, "message": f"Option '{option_id}' not found for '{crop}'"}


def get_schemes() -> list:
    return _load_data().get("government_schemes", [])
