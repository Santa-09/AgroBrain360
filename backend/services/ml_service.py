import io
import json
import logging
import os
import pickle
import warnings

import numpy as np
from PIL import Image
from sklearn.exceptions import InconsistentVersionWarning

log = logging.getLogger(__name__)

BASE_DIR = os.path.dirname(__file__)
MODELS_DIR = os.path.normpath(os.path.join(BASE_DIR, "..", "ml_models"))
PROJECT_ROOT = os.path.normpath(os.path.join(BASE_DIR, "..", ".."))
REPO_MODELS_DIR = os.path.join(PROJECT_ROOT, "ml_models")
BACKEND_CROP_RECOMMENDATION_DIR = os.path.join(MODELS_DIR, "crop_recommendation")
BACKEND_FERTILIZER_RECOMMENDATION_DIR = os.path.join(MODELS_DIR, "fertilizer_recommendation")
BACKEND_CROP_DISEASE_DIR = os.path.join(MODELS_DIR, "crop_disease")
BACKEND_INTENT_DIR = os.path.join(MODELS_DIR, "intent_detection")
BACKEND_LIVESTOCK_DIR = os.path.join(MODELS_DIR, "livestock")

_models = {}

_LIVESTOCK_KEYWORD_RULES = {
    "Foot and Mouth Disease": [
        "blister",
        "mouth sore",
        "drooling",
        "saliva",
        "hoof",
        "foot lesion",
        "lameness",
    ],
    "Mastitis": [
        "udder",
        "milk clot",
        "swollen teat",
        "mastitis",
        "teat pain",
    ],
    "Bloat": [
        "bloat",
        "bloated",
        "swollen belly",
        "distended abdomen",
        "gas",
    ],
    "Respiratory Infection": [
        "cough",
        "breathing",
        "nasal",
        "runny nose",
        "pneumonia",
        "respiratory",
        "sneez",
    ],
}


def _make_livestock_fallback_bundle() -> dict:
    return {
        "model_type": "keyword_fallback",
        "version": "1.0.0",
    }


def load_all_models() -> None:
    """Load all .pkl and .h5 models at startup. Called from main.py."""
    _load_pkl("crop_recommendation")
    _load_pkl("fertilizer_recommendation")
    _load_pkl("intent")
    _load_pkl("livestock")
    _load_keras("disease")


def _existing_nonempty_path(*paths: str) -> str | None:
    for path in paths:
        normalized = os.path.normpath(path)
        if os.path.exists(normalized) and os.path.getsize(normalized) > 0:
            return normalized
    return None


def _find_pickle_path(name: str) -> str | None:
    if name == "crop_recommendation":
        return _existing_nonempty_path(
            os.path.join(MODELS_DIR, "crop_recommendation_model.pkl"),
            os.path.join(MODELS_DIR, "crop_recommendation.pkl"),
            os.path.join(BACKEND_CROP_RECOMMENDATION_DIR, "crop_recommendation.pkl"),
            os.path.join(REPO_MODELS_DIR, "crop_recommendation", "crop_recommendation.pkl"),
        )
    if name == "intent":
        return _existing_nonempty_path(
            os.path.join(MODELS_DIR, "intent_model.pkl"),
            os.path.join(BACKEND_INTENT_DIR, "intent_model.pkl"),
            os.path.join(REPO_MODELS_DIR, "intent_detection", "intent_model.pkl"),
        )
    if name == "fertilizer_recommendation":
        return _existing_nonempty_path(
            os.path.join(MODELS_DIR, "fertilizer_recommendation.pkl"),
            os.path.join(BACKEND_FERTILIZER_RECOMMENDATION_DIR, "fertilizer_recommendation.pkl"),
            os.path.join(REPO_MODELS_DIR, "fertilizer_recommendation", "fertilizer_recommendation.pkl"),
        )
    if name == "livestock":
        return _existing_nonempty_path(
            os.path.join(MODELS_DIR, "livestock_model.pkl"),
            os.path.join(BACKEND_LIVESTOCK_DIR, "livestock_model.pkl"),
            os.path.join(REPO_MODELS_DIR, "livestock", "livestock_model.pkl"),
        )
    return _existing_nonempty_path(os.path.join(MODELS_DIR, f"{name}_model.pkl"))


def _find_keras_path(name: str) -> str | None:
    if name == "disease":
        return _existing_nonempty_path(
            os.path.join(MODELS_DIR, "disease_model.h5"),
            os.path.join(BACKEND_CROP_DISEASE_DIR, "disease_model.h5"),
            os.path.join(BACKEND_CROP_DISEASE_DIR, "disease_model.keras"),
            os.path.join(REPO_MODELS_DIR, "crop_disease", "disease_model.h5"),
            os.path.join(REPO_MODELS_DIR, "crop_disease", "disease_model.keras"),
        )
    return _existing_nonempty_path(os.path.join(MODELS_DIR, f"{name}_model.h5"))


def _load_pickle_artifact(*paths: str):
    path = _existing_nonempty_path(*paths)
    if not path:
        return None
    with open(path, "rb") as f:
        return pickle.load(f)


def _load_class_indices() -> dict[int, str]:
    class_map_path = _existing_nonempty_path(
        os.path.join(MODELS_DIR, "class_indices.json"),
        os.path.join(BACKEND_CROP_DISEASE_DIR, "class_indices.json"),
        os.path.join(REPO_MODELS_DIR, "crop_disease", "class_indices.json"),
    )
    if not class_map_path:
        return {}

    with open(class_map_path, encoding="utf-8") as f:
        indices = json.load(f)
    return {int(value): key for key, value in indices.items()}


def _normalize_bundle(name: str, bundle):
    if isinstance(bundle, dict):
        return bundle

    if name == "crop_recommendation":
        return {
            "model": bundle,
            "scaler": _load_pickle_artifact(
                os.path.join(BACKEND_CROP_RECOMMENDATION_DIR, "data", "scaler.pkl"),
                os.path.join(REPO_MODELS_DIR, "crop_recommendation", "data", "scaler.pkl"),
            ),
            "label_encoder": _load_pickle_artifact(
                os.path.join(BACKEND_CROP_RECOMMENDATION_DIR, "data", "label_encoder.pkl"),
                os.path.join(REPO_MODELS_DIR, "crop_recommendation", "data", "label_encoder.pkl"),
            ),
        }

    return bundle


def _load_pkl(name: str) -> None:
    path = _find_pickle_path(name)
    if not path:
        log.warning(f"No usable pickle model found for {name}; predictions unavailable")
        return

    try:
        with warnings.catch_warnings():
            warnings.filterwarnings("ignore", category=InconsistentVersionWarning)
            with open(path, "rb") as f:
                bundle = pickle.load(f)
        _models[name] = _normalize_bundle(name, bundle)
        log.info(f"Loaded {name} model from {path}")
    except ModuleNotFoundError as e:
        if name == "livestock":
            _models[name] = _make_livestock_fallback_bundle()
            log.info(
                "Livestock pickle at %s is incompatible with the current environment (%s). "
                "Using built-in keyword fallback instead.",
                path,
                e,
            )
            return
        log.error(f"Failed to load {name} model from {path}: {e}")
    except Exception as e:
        log.error(f"Failed to load {name} model from {path}: {e}")


def _load_keras(name: str) -> None:
    path = _find_keras_path(name)
    if not path:
        log.warning(f"No usable Keras model found for {name}; predictions unavailable")
        return

    try:
        os.environ.setdefault("TF_CPP_MIN_LOG_LEVEL", "2")
        os.environ.setdefault("TF_ENABLE_ONEDNN_OPTS", "0")
        warnings.filterwarnings("ignore", message=".*tf\\.losses\\.sparse_softmax_cross_entropy.*")
        warnings.filterwarnings("ignore", message=".*tf\\.executing_eagerly_outside_functions.*")
        import tensorflow as tf
        import absl.logging

        absl.logging.set_verbosity(absl.logging.ERROR)
        absl.logging.set_stderrthreshold("error")
        tf.get_logger().setLevel("ERROR")
        tf.compat.v1.logging.set_verbosity(tf.compat.v1.logging.ERROR)

        _models[name] = tf.keras.models.load_model(path)
        log.info(f"Loaded {name} model from {path}")
    except Exception as e:
        log.error(f"Failed to load {name} model from {path}: {e}")


def predict_crop_disease(image_bytes: bytes) -> dict:
    """Run disease model on uploaded image bytes."""
    model = _models.get("disease")
    if model is None:
        raise RuntimeError("Disease model not loaded")

    img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    img = img.resize((224, 224))
    arr = np.array(img) / 255.0
    arr = np.expand_dims(arr, 0).astype(np.float32)

    preds = model.predict(arr, verbose=0)[0]
    top_idx = int(np.argmax(preds))
    top_conf = float(preds[top_idx])

    disease = _load_class_indices().get(top_idx, str(top_idx))
    return {"disease": disease, "confidence": round(top_conf, 4)}


def predict_livestock(animal_type: str, symptoms: str) -> dict:
    bundle = _models.get("livestock")
    if bundle is None:
        bundle = _make_livestock_fallback_bundle()
        _models["livestock"] = bundle
    if not isinstance(bundle, dict):
        raise RuntimeError("Livestock model bundle is invalid")

    if bundle.get("model_type") == "keyword_fallback":
        return _predict_livestock_fallback(animal_type, symptoms)

    disease_pipe = bundle["disease_pipeline"]
    risk_pipe = bundle["risk_pipeline"]
    le_disease = bundle["disease_encoder"]
    risk_labels = bundle["risk_labels"]

    input_text = f"{animal_type.lower()} {symptoms.lower()}"
    disease_idx = disease_pipe.predict([input_text])[0]
    risk_idx = risk_pipe.predict([input_text])[0]
    disease = le_disease.inverse_transform([disease_idx])[0]
    risk_level = risk_labels.get(int(risk_idx), "medium")

    return {"disease": disease, "risk_level": risk_level}


def _predict_livestock_fallback(animal_type: str, symptoms: str) -> dict:
    del animal_type
    text = symptoms.lower().strip()

    matched_disease = "Healthy"
    matched_score = 0
    for disease, keywords in _LIVESTOCK_KEYWORD_RULES.items():
        score = sum(1 for keyword in keywords if keyword in text)
        if score > matched_score:
            matched_disease = disease
            matched_score = score

    if matched_score == 0:
        if any(token in text for token in ["fever", "letharg", "not eating", "loss of appetite"]):
            matched_disease = "Respiratory Infection"
            risk_level = "medium"
        else:
            matched_disease = "Healthy"
            risk_level = "low"
    else:
        if matched_disease == "Foot and Mouth Disease":
            risk_level = "high"
        elif matched_disease == "Healthy":
            risk_level = "low"
        else:
            risk_level = "medium"

    return {"disease": matched_disease, "risk_level": risk_level}


def predict_intent(query: str) -> dict:
    bundle = _models.get("intent")
    if bundle is None:
        raise RuntimeError("Intent model not loaded")
    if not isinstance(bundle, dict):
        raise RuntimeError("Intent model bundle is invalid")

    pipe = bundle["pipeline"]
    label_encoder = bundle["label_encoder"]
    routes = bundle.get("intent_routes", {})

    proba = pipe.predict_proba([query.lower()])[0]
    pred_idx = int(np.argmax(proba))
    intent = label_encoder.inverse_transform([pred_idx])[0]
    conf = float(proba[pred_idx])
    route = routes.get(intent, "Routes.dashboard")

    return {"intent": intent, "confidence": round(conf, 4), "route": route}


def predict_crop_recommendation(features: np.ndarray) -> dict:
    bundle = _models.get("crop_recommendation")
    if bundle is None:
        raise RuntimeError("Crop recommendation model not loaded")
    if not isinstance(bundle, dict):
        raise RuntimeError("Crop recommendation model bundle is invalid")

    model = bundle["model"]
    label_encoder = bundle["label_encoder"]
    scaler = bundle["scaler"]
    if scaler is None or label_encoder is None:
        raise RuntimeError("Crop recommendation metadata not loaded")

    scaled = scaler.transform(features)
    pred_idx = model.predict(scaled)[0]
    proba = model.predict_proba(scaled)[0]
    crop = label_encoder.inverse_transform([pred_idx])[0]
    conf = float(max(proba))

    return {"crop": crop, "confidence": round(conf, 4)}


def build_crop_recommendation_features(
    nitrogen: float,
    phosphorous: float,
    potassium: float,
    temperature: float,
    humidity: float,
    ph: float,
    rainfall: float,
) -> np.ndarray:
    return np.array(
        [[
            nitrogen,
            phosphorous,
            potassium,
            temperature,
            humidity,
            ph,
            rainfall,
            nitrogen + phosphorous + potassium,
            nitrogen / (phosphorous + 1e-6),
            nitrogen / (potassium + 1e-6),
            temperature * humidity / 100.0,
            (ph - 6.5) ** 2,
            rainfall / (temperature + 1e-6),
        ]],
        dtype=np.float32,
    )


def predict_fertilizer_recommendation(features: dict) -> dict:
    bundle = _models.get("fertilizer_recommendation")
    if bundle is None:
        raise RuntimeError("Fertilizer recommendation model not loaded")
    if not isinstance(bundle, dict):
        raise RuntimeError("Fertilizer recommendation model bundle is invalid")

    pipeline = bundle.get("pipeline")
    label_encoder = bundle.get("label_encoder")
    feature_columns = bundle.get("feature_columns")
    if pipeline is None or label_encoder is None or feature_columns is None:
        raise RuntimeError("Fertilizer recommendation metadata not loaded")

    row = {column: features[column] for column in feature_columns}
    frame = __import__("pandas").DataFrame([row])
    pred_idx = int(pipeline.predict(frame)[0])
    probabilities = pipeline.predict_proba(frame)[0]
    fertilizer = label_encoder.inverse_transform([pred_idx])[0]
    confidence = float(max(probabilities))

    ranked = sorted(
        [
            {
                "fertilizer": label_encoder.inverse_transform([idx])[0],
                "confidence": round(float(probability), 4),
            }
            for idx, probability in enumerate(probabilities)
        ],
        key=lambda item: item["confidence"],
        reverse=True,
    )

    return {
        "fertilizer": fertilizer,
        "confidence": round(confidence, 4),
        "top_recommendations": ranked[:3],
    }
