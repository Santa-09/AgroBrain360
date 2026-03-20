# backend/services/health_index_service.py


def compute_fhi(crop_score: float, soil_score: float, water_score: float,
                livestock_score: float, machinery_score: float) -> dict:
    """
    FHI = weighted average of 5 component scores.
    Weights match the guide: crop 35%, soil 25%, water 20%, livestock 10%, machinery 10%.
    """
    fhi = (
        crop_score      * 0.35 +
        soil_score      * 0.25 +
        water_score     * 0.20 +
        livestock_score * 0.10 +
        machinery_score * 0.10
    )
    fhi = round(min(max(fhi, 0), 100), 2)

    if fhi >= 80:
        label = "Excellent"
    elif fhi >= 60:
        label = "Good"
    elif fhi >= 40:
        label = "Fair"
    else:
        label = "Poor"

    return {
        "fhi_score":       fhi,
        "crop_score":      crop_score,
        "soil_score":      soil_score,
        "water_score":     water_score,
        "livestock_score": livestock_score,
        "machinery_score": machinery_score,
        "label":           label,
    }