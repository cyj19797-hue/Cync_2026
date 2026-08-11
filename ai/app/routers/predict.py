from fastapi import APIRouter
from pydantic import BaseModel, Field

router = APIRouter(tags=["predict"])


class PredictRequest(BaseModel):
    text: str = Field(..., min_length=1)


class PredictResponse(BaseModel):
    label: str
    score: float


@router.post("/predict", response_model=PredictResponse)
def predict(body: PredictRequest) -> PredictResponse:
    # Placeholder inference — replace with a real model later.
    text = body.text.strip().lower()
    label = "positive" if "good" in text or "좋아" in text else "neutral"
    score = 0.92 if label == "positive" else 0.55
    return PredictResponse(label=label, score=score)
