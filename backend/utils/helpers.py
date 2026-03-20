# backend/utils/helpers.py
import io
import numpy as np
from PIL import Image


def image_bytes_to_array(image_bytes: bytes,
                         size: tuple = (224, 224)) -> np.ndarray:
    img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    img = img.resize(size)
    return np.array(img) / 255.0