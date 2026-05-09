import logging

from fastapi import APIRouter

LOGGER = logging.getLogger(__name__)

router = APIRouter()


@router.get("/hello")
def say_hello():
    return 'Hello, this is the FHIR Questionnaire Mapper API v2!'
