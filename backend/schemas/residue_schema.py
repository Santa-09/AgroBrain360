# backend/schemas/residue_schema.py
from pydantic import BaseModel
from typing import List, Optional


class ResidueRequest(BaseModel):
    crop: str
    language: str = "en"


class ResidueOption(BaseModel):
    id:               str
    title:            str
    income_potential: str
    time_required:    str
    difficulty:       str
    steps:            List[str]
    benefits:         List[str]
    market:           str


class ResidueResponse(BaseModel):
    crop:              str
    residue_type:      str
    quantity_per_acre: str
    options:           List[ResidueOption]