# backend/routes/residue_routes.py
from fastapi import APIRouter, File, Form, HTTPException, UploadFile
from services.residue_service import (
    get_supported_crops, get_recommendations,
    get_option_detail, get_schemes,
)
from services import response_service

router = APIRouter(prefix="/residue", tags=["Crop Residue"])


@router.post("/analyze")
async def analyze_residue(
    file: UploadFile = File(...),
    residue_type: str = Form(...),
    moisture: str = Form("Medium"),
    lang: str = Form("en"),
):
    if file.content_type not in ("image/jpeg", "image/png", "image/jpg"):
        raise HTTPException(status_code=400, detail="Only JPEG/PNG images accepted")

    crop_key = residue_type.lower().strip()
    recommendation = get_recommendations(crop_key)

    if not recommendation["found"]:
        fallback_options = {
            "Compost": 2200.0,
            "Cattle Fodder": 2800.0,
            "Bio-Briquettes": 3400.0,
        }
        return response_service.build(
            {
                "residue_type": residue_type,
                "moisture_level": moisture,
                "estimated_quantity_kg": 400.0,
                "best_option": "Bio-Briquettes",
                "projected_earnings": 3400.0,
                "all_options": fallback_options,
                "description": "Cloud residue fallback generated because no crop-specific dataset entry was found.",
                "source": "cloud",
            },
            lang=lang,
        )

    quantity_per_acre = float(recommendation.get("quantity_per_acre", 400))
    moisture_factor = {
        "low (dry)": 1.0,
        "medium": 0.9,
        "high (wet)": 0.75,
    }.get(moisture.lower().strip(), 0.9)
    estimated_quantity = round(quantity_per_acre * moisture_factor, 2)

    options = recommendation.get("options", [])
    earnings_map = {
        option["title"]: round(float(option.get("income_per_acre", 0.0)), 2)
        for option in options
    }

    if not earnings_map:
        earnings_map = {
            "Compost": round(estimated_quantity * 5.5, 2),
            "Cattle Fodder": round(estimated_quantity * 7.0, 2),
            "Bio-Briquettes": round(estimated_quantity * 14.0, 2),
        }

    best_option = max(earnings_map, key=earnings_map.get)

    return response_service.build(
        {
            "residue_type": residue_type,
            "moisture_level": moisture,
            "estimated_quantity_kg": estimated_quantity,
            "best_option": best_option,
            "projected_earnings": earnings_map[best_option],
            "all_options": earnings_map,
            "description": f"Cloud analysis prepared for {residue_type} residue with {moisture.lower()} moisture.",
            "source": "cloud",
        },
        lang=lang,
    )


@router.get("/crops")
def list_crops():
    return response_service.build({"crops": get_supported_crops()})


@router.get("/recommendations/{crop}")
def recommendations(crop: str, lang: str = "en"):
    result = get_recommendations(crop)
    if not result["found"]:
        raise HTTPException(status_code=404, detail=result["message"])
    return response_service.build(result, lang=lang)


@router.get("/recommendations/{crop}/{option_id}")
def option_detail(crop: str, option_id: str):
    result = get_option_detail(crop, option_id)
    if not result["found"]:
        raise HTTPException(status_code=404, detail=result["message"])
    return response_service.build(result)


@router.get("/schemes")
def schemes():
    return response_service.build({"schemes": get_schemes()})
