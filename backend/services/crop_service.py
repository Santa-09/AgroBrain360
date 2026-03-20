# backend/services/crop_service.py
from services import ml_service

DISEASE_ADVICE = {
    "Tomato___Early_blight": {
        "severity": "Medium", "risk_level": "MEDIUM",
        "treatment": "Spray Mancozeb or Chlorothalonil every 7 days.",
        "prevention": "Avoid overhead irrigation. Rotate crops. Remove plant debris.",
    },
    "Tomato___Late_blight": {
        "severity": "High", "risk_level": "HIGH",
        "treatment": "Spray Metalaxyl + Mancozeb. Remove severely infected plants.",
        "prevention": "Use resistant varieties. Avoid wet foliage.",
    },
    "Tomato___healthy": {
        "severity": "None", "risk_level": "LOW",
        "treatment": "No treatment required.",
        "prevention": "Maintain proper irrigation and balanced fertilization.",
    },
    "Potato___Late_blight": {
        "severity": "High", "risk_level": "HIGH",
        "treatment": "Spray Metalaxyl + Mancozeb. Repeat every 5 days.",
        "prevention": "Use resistant varieties. Hill up soil around plants.",
    },
    "Potato___healthy": {
        "severity": "None", "risk_level": "LOW",
        "treatment": "No treatment required.",
        "prevention": "Use certified seed tubers. Rotate crops.",
    },
    "Rice___Leaf_Blast": {
        "severity": "High", "risk_level": "HIGH",
        "treatment": "Spray Tricyclazole or Isoprothiolane fungicide.",
        "prevention": "Use resistant varieties. Avoid excess nitrogen.",
    },
    "Rice___healthy": {
        "severity": "None", "risk_level": "LOW",
        "treatment": "No treatment required.",
        "prevention": "Maintain proper irrigation and spacing.",
    },
    "Pepper,_bell___Bacterial_spot": {
        "severity": "Medium", "risk_level": "MEDIUM",
        "treatment": "Spray Copper Hydroxide every 5-7 days.",
        "prevention": "Use disease-free seeds. Avoid overhead irrigation.",
    },
    "Pepper,_bell___healthy": {
        "severity": "None", "risk_level": "LOW",
        "treatment": "No treatment required.",
        "prevention": "Maintain proper irrigation and balanced fertilization.",
    },
}


def analyze_disease(image_bytes: bytes) -> dict:
    result  = ml_service.predict_crop_disease(image_bytes)
    disease = result["disease"]
    advice  = DISEASE_ADVICE.get(disease, {
        "severity":   "Unknown",
        "risk_level": "UNKNOWN",
        "treatment":  "Consult your local agriculture officer.",
        "prevention": "Monitor crop regularly.",
    })
    return {
        "disease":    disease,
        "confidence": result["confidence"],
        **advice,
    }


def recommend_fertilizer(features: dict) -> dict:
    result = ml_service.predict_fertilizer_recommendation(features)
    fertilizer = result["fertilizer"]

    fertilizer_guidance = {
        "Urea": {
            "application_tip": "Apply in split doses and irrigate lightly after application.",
            "summary": "High nitrogen fertilizer suited for vegetative growth support.",
        },
        "DAP": {
            "application_tip": "Use during basal application and avoid overuse in phosphorus-rich soil.",
            "summary": "Balanced starter fertilizer with strong phosphorus support.",
        },
        "17-17-17": {
            "application_tip": "Broadcast evenly across moist soil for balanced nutrient support.",
            "summary": "Balanced NPK fertilizer for general crop nutrition.",
        },
        "14-35-14": {
            "application_tip": "Best used early when root establishment and flowering support are needed.",
            "summary": "High-phosphorus fertilizer for root and flowering development.",
        },
        "28-28": {
            "application_tip": "Use in moderate amounts and combine with soil moisture management.",
            "summary": "Nitrogen-phosphorus fertilizer for early growth stages.",
        },
        "20-20": {
            "application_tip": "Apply uniformly and monitor crop response before repeating.",
            "summary": "Balanced nitrogen-phosphorus fertilizer for steady crop growth.",
        },
        "10-26-26": {
            "application_tip": "Suitable where phosphorus and potassium demand is higher than nitrogen.",
            "summary": "Low-nitrogen fertilizer for flowering and fruiting stages.",
        },
    }.get(
        fertilizer,
        {
            "application_tip": "Apply according to soil test values and local agronomy guidance.",
            "summary": "Recommended fertilizer based on the trained model prediction.",
        },
    )

    return {
        **result,
        **fertilizer_guidance,
    }
