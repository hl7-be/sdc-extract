import logging

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from starlette.middleware.cors import CORSMiddleware

from src.server.routers import v2
from src.server.utils import OperationOutcomeException

logging.basicConfig(level=logging.INFO)

LOGGER = logging.getLogger(__name__)

app = FastAPI(title="Tiro SDC Extract service")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(OperationOutcomeException)
async def operation_outcome_exception_handler(request: Request, exc: OperationOutcomeException):
    return JSONResponse(
        status_code=exc.status_code,
        content=exc.detail,
        media_type="application/fhir+json",
    )


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    LOGGER.exception("Unhandled exception")
    return JSONResponse(status_code=500, content={"detail": "Internal server error"})


app.include_router(v2.router, prefix="/api/v2")

