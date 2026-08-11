"""Cync AI server — FastAPI entrypoint."""

from fastapi import FastAPI

from app.routers import health, predict

app = FastAPI(title="Cync AI", version="0.1.0")

app.include_router(health.router)
app.include_router(predict.router)
