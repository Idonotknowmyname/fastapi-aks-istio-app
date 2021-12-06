import os
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()


class Response(BaseModel):
    message: str
    version: str


@app.get("/hello", response_model=Response)
def hello_world():
    return {"message": "Hello world", "version": os.environ["SERVICE_VERSION"]}
