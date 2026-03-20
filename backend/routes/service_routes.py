import math

from fastapi import APIRouter

from services import response_service

router = APIRouter(prefix="/services", tags=["Hyperlocal Services"])

SERVICES = [
    {
        "id": "svc_1",
        "name": "Dr. Ramesh Kumar",
        "category": "Vets",
        "specialty": "Cattle and Buffalo Specialist",
        "phone": "9876543210",
        "rating": 4.8,
        "open": True,
        "address": "Near Bus Stand, Bhubaneswar",
        "lat": 20.3055,
        "lng": 85.8174,
    },
    {
        "id": "svc_2",
        "name": "Kishan Agro Inputs",
        "category": "Input Dealers",
        "specialty": "Seeds, fertilizers, pesticides",
        "phone": "9123456789",
        "rating": 4.5,
        "open": True,
        "address": "Main Market Road, Bhubaneswar",
        "lat": 20.3018,
        "lng": 85.8402,
    },
    {
        "id": "svc_3",
        "name": "Sharma Tractor Works",
        "category": "Repair Centers",
        "specialty": "Tractor and harvester repair",
        "phone": "9988776655",
        "rating": 4.3,
        "open": False,
        "address": "Industrial Area, Sector 4, Cuttack",
        "lat": 20.4706,
        "lng": 85.8792,
    },
    {
        "id": "svc_4",
        "name": "Government Veterinary Hospital",
        "category": "Vets",
        "specialty": "All animals, low-cost care",
        "phone": "06742301234",
        "rating": 4.0,
        "open": True,
        "address": "District HQ Road, Bhubaneswar",
        "lat": 20.2877,
        "lng": 85.8349,
    },
    {
        "id": "svc_5",
        "name": "APMC Grain Market",
        "category": "Mandis",
        "specialty": "Wheat, rice, vegetables",
        "phone": "9876001234",
        "rating": 4.2,
        "open": True,
        "address": "NH-16, Ring Road, Cuttack",
        "lat": 20.4561,
        "lng": 85.8911,
    },
    {
        "id": "svc_6",
        "name": "Village Pump Repair Hub",
        "category": "Repair Centers",
        "specialty": "Pump and sprayer servicing",
        "phone": "9437001122",
        "rating": 4.4,
        "open": True,
        "address": "Canal Road Junction, Puri",
        "lat": 19.8203,
        "lng": 85.8267,
    },
    {
        "id": "svc_7",
        "name": "Green Soil Inputs",
        "category": "Input Dealers",
        "specialty": "Organic manure and micronutrients",
        "phone": "9438123456",
        "rating": 4.6,
        "open": True,
        "address": "Weekly Market Square, Sambalpur",
        "lat": 21.4722,
        "lng": 83.9877,
    },
    {
        "id": "svc_8",
        "name": "Farmer Support Mandi",
        "category": "Mandis",
        "specialty": "Pulses, maize, millet",
        "phone": "9777771234",
        "rating": 4.1,
        "open": True,
        "address": "Old Highway Yard, Rourkela",
        "lat": 22.2538,
        "lng": 84.8602,
    },
]


def _distance_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    radius_km = 6371.0
    d_lat = math.radians(lat2 - lat1)
    d_lng = math.radians(lng2 - lng1)
    a = (
        math.sin(d_lat / 2) ** 2
        + math.cos(math.radians(lat1))
        * math.cos(math.radians(lat2))
        * math.sin(d_lng / 2) ** 2
    )
    return round(radius_km * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a)), 2)


@router.get("/nearby")
def get_nearby_services(
    category: str | None = None,
    q: str | None = None,
    lat: float | None = None,
    lng: float | None = None,
    lang: str = "en",
):
    results = [dict(service) for service in SERVICES]

    if category and category != "All":
        results = [service for service in results if service["category"] == category]

    if q:
        query = q.strip().lower()
        results = [
            service
            for service in results
            if query in service["name"].lower()
            or query in service["specialty"].lower()
            or query in service["address"].lower()
        ]

    for service in results:
        if lat is not None and lng is not None:
            service["distance"] = _distance_km(lat, lng, service["lat"], service["lng"])
        else:
            service["distance"] = 9999.0

    results.sort(key=lambda item: item["distance"])
    return response_service.build({"services": results}, lang=lang)
