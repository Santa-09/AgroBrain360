# backend/services/livestock_service.py
from services import ml_service

FIRST_AID = {
    "Foot and Mouth Disease": "Isolate animal immediately. Clean mouth/feet with antiseptic.",
    "Mastitis":               "Strip affected quarters. Apply teat dip. Contact vet.",
    "Bloat":                  "Walk animal slowly. Apply anti-bloat medicine. Call vet.",
    "Respiratory Infection":  "Keep animal warm and dry. Ensure fresh water. Contact vet.",
    "Healthy":                "No action needed. Continue routine care.",
}


def diagnose(animal_type: str, symptoms: str) -> dict:
    result     = ml_service.predict_livestock(animal_type, symptoms)
    disease    = result["disease"]
    risk_level = result["risk_level"]
    first_aid  = FIRST_AID.get(disease, "Contact your veterinarian immediately.")
    treatment  = f"Consult a vet for {disease} treatment protocol."
    return {
        "disease":    disease,
        "risk_level": risk_level,
        "treatment":  treatment,
        "first_aid":  first_aid,
    }