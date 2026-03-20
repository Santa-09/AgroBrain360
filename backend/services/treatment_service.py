# backend/services/treatment_service.py
# ─────────────────────────────────────────────────────────────
# Returns detailed treatment plans for crop diseases and
# livestock conditions. Used by crop and livestock routes.
# ─────────────────────────────────────────────────────────────

import logging

log = logging.getLogger(__name__)

# ── Crop disease treatment plans ─────────────────────────────
CROP_TREATMENTS = {
    "Rice___Leaf_Blast": {
        "disease":    "Rice Leaf Blast",
        "pathogen":   "Magnaporthe oryzae (fungus)",
        "severity":   "High",
        "risk_level": "HIGH",
        "immediate_action": [
            "Stop overhead irrigation immediately.",
            "Remove and destroy heavily infected plant parts.",
            "Do not apply excess nitrogen fertilizer.",
        ],
        "chemical_treatment": {
            "fungicide":    "Tricyclazole 75 WP",
            "dose":         "600g per acre mixed in 200L water",
            "frequency":    "Spray every 10–14 days, 2–3 applications",
            "timing":       "Early morning or evening — avoid spraying in rain",
            "alternatives": ["Isoprothiolane 40 EC — 500ml/acre",
                             "Azoxystrobin 23 SC — 200ml/acre"],
        },
        "organic_treatment": [
            "Spray Pseudomonas fluorescens 2% solution.",
            "Apply Trichoderma viride at 2.5 kg/acre with FYM.",
        ],
        "prevention": [
            "Use blast-resistant varieties (IR-64, Swarnadhan).",
            "Maintain proper plant spacing (20×15 cm).",
            "Avoid excess nitrogen — use split doses.",
            "Drain fields periodically to reduce humidity.",
        ],
        "recovery_days": 14,
    },

    "Potato___Late_blight": {
        "disease":    "Potato Late Blight",
        "pathogen":   "Phytophthora infestans (oomycete)",
        "severity":   "Very High",
        "risk_level": "HIGH",
        "immediate_action": [
            "Act within 24 hours — disease spreads extremely fast.",
            "Remove and bag all infected plant material.",
            "Do not compost infected material — burn or bury deep.",
            "Stop overhead irrigation.",
        ],
        "chemical_treatment": {
            "fungicide":    "Metalaxyl 8% + Mancozeb 64% WP",
            "dose":         "1 kg per acre in 200L water",
            "frequency":    "Every 5–7 days, up to 3 applications",
            "timing":       "Before rain forecast or after light rain",
            "alternatives": ["Cymoxanil 8% + Mancozeb 64% WP — 600g/acre",
                             "Dimethomorph 50 WP — 300g/acre"],
        },
        "organic_treatment": [
            "Spray Bordeaux mixture (1%) as preventive.",
            "Apply copper oxychloride 50 WP at 3g/litre.",
        ],
        "prevention": [
            "Use certified disease-free seed tubers.",
            "Hill up soil around plants to protect tubers.",
            "Avoid planting in low-lying waterlogged fields.",
            "Monitor weather — cool humid conditions trigger outbreak.",
        ],
        "recovery_days": 21,
    },

    "Tomato___Early_blight": {
        "disease":    "Tomato Early Blight",
        "pathogen":   "Alternaria solani (fungus)",
        "severity":   "Medium",
        "risk_level": "MEDIUM",
        "immediate_action": [
            "Remove infected lower leaves immediately.",
            "Do not water from above — use drip or furrow irrigation.",
            "Avoid working in field when plants are wet.",
        ],
        "chemical_treatment": {
            "fungicide":    "Mancozeb 75 WP",
            "dose":         "600g per acre in 200L water",
            "frequency":    "Every 7–10 days, 2–3 applications",
            "timing":       "Apply in morning before temperature rises",
            "alternatives": ["Chlorothalonil 75 WP — 500g/acre",
                             "Azoxystrobin 23 SC — 200ml/acre"],
        },
        "organic_treatment": [
            "Spray neem oil 2% solution every 7 days.",
            "Apply Trichoderma-based biofungicide.",
        ],
        "prevention": [
            "Rotate crops — avoid planting tomato in same field 2 years in a row.",
            "Mulch soil to prevent spore splash from ground.",
            "Ensure proper spacing for air circulation.",
            "Remove plant debris after harvest.",
        ],
        "recovery_days": 14,
    },

    "Tomato___Late_blight": {
        "disease":    "Tomato Late Blight",
        "pathogen":   "Phytophthora infestans (oomycete)",
        "severity":   "High",
        "risk_level": "HIGH",
        "immediate_action": [
            "Remove and destroy all infected plant parts immediately.",
            "Isolate infected plants from healthy ones.",
            "Apply fungicide within 24 hours.",
        ],
        "chemical_treatment": {
            "fungicide":    "Metalaxyl + Mancozeb WP",
            "dose":         "800g per acre in 200L water",
            "frequency":    "Every 5–7 days, up to 3 applications",
            "timing":       "Before expected rain or in cool humid weather",
            "alternatives": ["Cymoxanil + Mancozeb — 600g/acre"],
        },
        "organic_treatment": [
            "Bordeaux mixture 1% spray as preventive.",
        ],
        "prevention": [
            "Use resistant varieties.",
            "Avoid wetting foliage during irrigation.",
            "Ensure good drainage in field.",
        ],
        "recovery_days": 21,
    },

    "Pepper,_bell___Bacterial_spot": {
        "disease":    "Pepper Bacterial Spot",
        "pathogen":   "Xanthomonas campestris (bacteria)",
        "severity":   "Medium",
        "risk_level": "MEDIUM",
        "immediate_action": [
            "Remove and destroy infected leaves and fruits.",
            "Avoid overhead irrigation.",
            "Disinfect tools with 10% bleach solution.",
        ],
        "chemical_treatment": {
            "fungicide":    "Copper Hydroxide 77 WP",
            "dose":         "500g per acre in 200L water",
            "frequency":    "Every 5–7 days, 3 applications",
            "timing":       "Apply during dry weather",
            "alternatives": ["Copper Oxychloride 50 WP — 600g/acre"],
        },
        "organic_treatment": [
            "Spray Bacillus subtilis-based biofungicide.",
            "Apply neem cake at 100kg/acre to soil.",
        ],
        "prevention": [
            "Use disease-free certified seeds.",
            "Treat seeds with hot water (50°C for 25 min) before sowing.",
            "Rotate crops annually.",
        ],
        "recovery_days": 14,
    },

    "Tomato___healthy": {
        "disease":    "Healthy",
        "severity":   "None",
        "risk_level": "LOW",
        "immediate_action": ["No action required."],
        "chemical_treatment": {
            "fungicide":    "None required",
            "dose":         "N/A",
            "frequency":    "N/A",
            "timing":       "N/A",
            "alternatives": [],
        },
        "organic_treatment": ["Continue routine care and monitoring."],
        "prevention": [
            "Maintain balanced fertilization (NPK as per soil test).",
            "Ensure proper drainage.",
            "Monitor weekly for early signs of disease.",
        ],
        "recovery_days": 0,
    },

    "Rice___healthy":    {"disease": "Healthy", "severity": "None", "risk_level": "LOW",
                          "immediate_action": ["No action required."],
                          "chemical_treatment": {"fungicide": "None", "dose": "N/A",
                                                 "frequency": "N/A", "timing": "N/A", "alternatives": []},
                          "organic_treatment": ["Continue routine care."],
                          "prevention": ["Regular monitoring."], "recovery_days": 0},

    "Potato___healthy":  {"disease": "Healthy", "severity": "None", "risk_level": "LOW",
                          "immediate_action": ["No action required."],
                          "chemical_treatment": {"fungicide": "None", "dose": "N/A",
                                                 "frequency": "N/A", "timing": "N/A", "alternatives": []},
                          "organic_treatment": ["Continue routine care."],
                          "prevention": ["Regular monitoring."], "recovery_days": 0},

    "Pepper,_bell___healthy": {"disease": "Healthy", "severity": "None", "risk_level": "LOW",
                                "immediate_action": ["No action required."],
                                "chemical_treatment": {"fungicide": "None", "dose": "N/A",
                                                       "frequency": "N/A", "timing": "N/A", "alternatives": []},
                                "organic_treatment": ["Continue routine care."],
                                "prevention": ["Regular monitoring."], "recovery_days": 0},
}

# ── Livestock treatment plans ─────────────────────────────────
LIVESTOCK_TREATMENTS = {
    "Foot and Mouth Disease": {
        "disease":         "Foot and Mouth Disease (FMD)",
        "risk_level":      "HIGH",
        "contagious":      True,
        "immediate_action": [
            "Isolate affected animal from herd immediately.",
            "Disinfect all shared equipment and water troughs.",
            "Notify nearest veterinary officer (mandatory reporting).",
            "Do not move animals off the farm.",
        ],
        "first_aid": [
            "Clean mouth lesions with 1% potassium permanganate solution.",
            "Wash feet with antiseptic solution (Dettol diluted).",
            "Provide soft, easy-to-eat feed and fresh water.",
            "Keep animal in dry, clean shelter.",
        ],
        "veterinary_treatment": [
            "Anti-inflammatory injection (Meloxicam) — by vet only.",
            "Vitamin B-complex injection to support recovery.",
            "Secondary infection antibiotics if prescribed.",
        ],
        "prevention": [
            "Vaccinate all cattle every 6 months (FMD vaccine available free at govt. centres).",
            "Quarantine all new animals for 21 days before mixing with herd.",
            "Disinfect vehicle tyres entering farm.",
        ],
        "recovery_days":   14,
        "vet_required":    True,
    },

    "Mastitis": {
        "disease":         "Mastitis",
        "risk_level":      "MEDIUM",
        "contagious":      False,
        "immediate_action": [
            "Strip affected quarter completely before and after milking.",
            "Apply teat dip (iodine-based) after every milking.",
            "Milk affected cow last to prevent spread.",
            "Discard milk from affected quarter.",
        ],
        "first_aid": [
            "Massage udder gently with warm cloth.",
            "Apply camphor oil externally to reduce swelling.",
            "Ensure clean, dry bedding.",
        ],
        "veterinary_treatment": [
            "Intramammary antibiotic infusion — by vet only.",
            "Oxytocin injection to aid milk let-down if needed.",
            "NSAIDs for pain and swelling.",
        ],
        "prevention": [
            "Clean udder before milking with warm water.",
            "Use post-milking teat dip every time.",
            "Ensure milking equipment is properly cleaned.",
            "Provide dry cow therapy at end of lactation.",
        ],
        "recovery_days":   7,
        "vet_required":    True,
    },

    "Bloat": {
        "disease":         "Bloat (Tympany)",
        "risk_level":      "HIGH",
        "contagious":      False,
        "immediate_action": [
            "Walk the animal slowly — do NOT let it lie down.",
            "Keep animal's front legs elevated (head uphill).",
            "Insert stomach tube through mouth to release gas if available.",
            "Call vet immediately if distension is severe.",
        ],
        "first_aid": [
            "Drench with turpentine oil (30ml) mixed in 500ml water.",
            "Apply anti-bloat drench (Bloatguard or similar) if available.",
            "Massage left flank gently in circular motion.",
        ],
        "veterinary_treatment": [
            "Trocar and cannula puncture of rumen — emergency, vet only.",
            "Anti-foaming agent (simethicone) injection.",
        ],
        "prevention": [
            "Do not allow animals to graze on wet legume pasture on empty stomach.",
            "Introduce new lush pasture gradually over 7 days.",
            "Feed dry roughage before releasing onto lush pasture.",
        ],
        "recovery_days":   2,
        "vet_required":    True,
    },

    "Respiratory Infection": {
        "disease":         "Respiratory Infection",
        "risk_level":      "MEDIUM",
        "contagious":      True,
        "immediate_action": [
            "Isolate affected animal from herd.",
            "Keep animal in warm, dry, well-ventilated shelter.",
            "Ensure access to clean fresh water.",
        ],
        "first_aid": [
            "Steam inhalation with eucalyptus oil — 10 min twice daily.",
            "Vitamin C supplementation in feed.",
            "Electrolyte solution if animal is not drinking.",
        ],
        "veterinary_treatment": [
            "Antibiotic injection (Oxytetracycline or Enrofloxacin) — vet only.",
            "Anti-inflammatory (Meloxicam) to reduce fever.",
            "Expectorant if severe nasal discharge.",
        ],
        "prevention": [
            "Vaccinate against common respiratory diseases (BRD vaccine).",
            "Avoid sudden changes in temperature — provide blanket in winter.",
            "Ensure proper ventilation in shed — no drafts.",
            "Quarantine new animals for 3 weeks.",
        ],
        "recovery_days":   7,
        "vet_required":    True,
    },

    "Healthy": {
        "disease":         "Healthy",
        "risk_level":      "LOW",
        "contagious":      False,
        "immediate_action": ["No action required. Continue routine care."],
        "first_aid":       ["Routine deworming every 3 months.",
                            "Regular vaccination as per schedule."],
        "veterinary_treatment": ["Annual health check recommended."],
        "prevention": [
            "Maintain clean water and feed.",
            "Regular deworming every 3 months.",
            "Keep vaccination records up to date.",
        ],
        "recovery_days":   0,
        "vet_required":    False,
    },
}


def get_crop_treatment(disease: str) -> dict:
    """Returns full treatment plan for a crop disease."""
    plan = CROP_TREATMENTS.get(disease)
    if plan:
        return {"found": True, "disease": disease, **plan}
    return {
        "found":   False,
        "disease": disease,
        "message": "No specific treatment plan available. Consult your local KVK.",
        "immediate_action": ["Contact Kisan Call Center: 1800-180-1551"],
        "risk_level": "UNKNOWN",
    }


def get_livestock_treatment(disease: str) -> dict:
    """Returns full treatment plan for a livestock disease."""
    plan = LIVESTOCK_TREATMENTS.get(disease)
    if plan:
        return {"found": True, "disease": disease, **plan}
    return {
        "found":   False,
        "disease": disease,
        "message": "Contact veterinarian immediately.",
        "immediate_action": ["Isolate animal. Call vet."],
        "risk_level": "UNKNOWN",
        "vet_required": True,
    }