# backend/services/roi_service.py
# ─────────────────────────────────────────────────────────────
# Calculates cost vs loss estimates in INR for crop diseases.
# Helps farmers decide whether treatment is worth the cost.
# ─────────────────────────────────────────────────────────────

import logging

log = logging.getLogger(__name__)

# Per-acre cost and loss estimates in INR
DISEASE_ECONOMICS = {
    "Rice___Leaf_Blast": {
        "treatment_cost_per_acre":     800,
        "loss_if_untreated_per_acre":  15000,
        "yield_loss_percent":          40,
        "fungicide":                   "Tricyclazole 75 WP — 600g/acre",
        "applications":                2,
    },
    "Potato___Late_blight": {
        "treatment_cost_per_acre":     1200,
        "loss_if_untreated_per_acre":  25000,
        "yield_loss_percent":          70,
        "fungicide":                   "Metalaxyl + Mancozeb — 1kg/acre",
        "applications":                3,
    },
    "Tomato___Early_blight": {
        "treatment_cost_per_acre":     600,
        "loss_if_untreated_per_acre":  12000,
        "yield_loss_percent":          30,
        "fungicide":                   "Mancozeb 75 WP — 600g/acre",
        "applications":                2,
    },
    "Tomato___Late_blight": {
        "treatment_cost_per_acre":     1000,
        "loss_if_untreated_per_acre":  20000,
        "yield_loss_percent":          60,
        "fungicide":                   "Metalaxyl + Mancozeb — 800g/acre",
        "applications":                3,
    },
    "Pepper,_bell___Bacterial_spot": {
        "treatment_cost_per_acre":     500,
        "loss_if_untreated_per_acre":  8000,
        "yield_loss_percent":          25,
        "fungicide":                   "Copper Hydroxide 77 WP — 500g/acre",
        "applications":                2,
    },
    "Rice___healthy": {
        "treatment_cost_per_acre":     0,
        "loss_if_untreated_per_acre":  0,
        "yield_loss_percent":          0,
        "fungicide":                   "None required",
        "applications":                0,
    },
    "Tomato___healthy": {
        "treatment_cost_per_acre":     0,
        "loss_if_untreated_per_acre":  0,
        "yield_loss_percent":          0,
        "fungicide":                   "None required",
        "applications":                0,
    },
    "Potato___healthy": {
        "treatment_cost_per_acre":     0,
        "loss_if_untreated_per_acre":  0,
        "yield_loss_percent":          0,
        "fungicide":                   "None required",
        "applications":                0,
    },
}

DEFAULT_ECONOMICS = {
    "treatment_cost_per_acre":     500,
    "loss_if_untreated_per_acre":  10000,
    "yield_loss_percent":          20,
    "fungicide":                   "Consult local agriculture officer",
    "applications":                2,
}


def calculate_roi(disease: str, crop_type: str = None,
                  area_acres: float = 1.0) -> dict:
    """
    Returns treatment cost, potential loss, and savings for given area.
    """
    area_acres = max(0.1, float(area_acres))
    econ       = DISEASE_ECONOMICS.get(disease, DEFAULT_ECONOMICS)

    treatment_cost = round(econ["treatment_cost_per_acre"]    * area_acres)
    potential_loss = round(econ["loss_if_untreated_per_acre"] * area_acres)
    savings        = potential_loss - treatment_cost
    roi_ratio      = round(savings / treatment_cost, 1) if treatment_cost > 0 else 0

    if treatment_cost == 0:
        recommendation = "No treatment needed — crop is healthy."
        urgency        = "none"
    elif potential_loss > treatment_cost * 3:
        recommendation = "Treat immediately — high return on investment."
        urgency        = "high"
    elif potential_loss > treatment_cost:
        recommendation = "Treatment is cost-effective. Proceed."
        urgency        = "medium"
    else:
        recommendation = "Monitor closely. Consult agriculture officer."
        urgency        = "low"

    return {
        "disease":             disease,
        "area_acres":          area_acres,
        "treatment_cost_inr":  treatment_cost,
        "loss_if_untreated_inr": potential_loss,
        "savings_inr":         savings,
        "roi_ratio":           roi_ratio,         # savings per ₹1 spent
        "yield_loss_percent":  econ["yield_loss_percent"],
        "fungicide":           econ["fungicide"],
        "applications":        econ["applications"],
        "treat_recommended":   potential_loss > treatment_cost,
        "urgency":             urgency,
        "recommendation":      recommendation,
    }


def compare_treatments(disease: str, area_acres: float = 1.0) -> dict:
    """
    Compares cost of treating now vs treating late vs not treating.
    Helps farmers understand financial impact of delay.
    """
    econ       = DISEASE_ECONOMICS.get(disease, DEFAULT_ECONOMICS)
    area_acres = max(0.1, float(area_acres))

    treat_now   = round(econ["treatment_cost_per_acre"] * area_acres)
    treat_late  = round(econ["treatment_cost_per_acre"] * area_acres * 1.5)  # more applications
    no_treatment = round(econ["loss_if_untreated_per_acre"] * area_acres)

    return {
        "disease":           disease,
        "area_acres":        area_acres,
        "treat_now_cost":    treat_now,
        "treat_late_cost":   treat_late,
        "no_treatment_loss": no_treatment,
        "savings_vs_late":   treat_late - treat_now,
        "savings_vs_none":   no_treatment - treat_now,
        "best_action":       "Treat immediately for maximum savings.",
    }