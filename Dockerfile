FROM python:3.9-slim-buster

ARG SERVICE_VERSION="unversioned"

ENV SERVICE_VERSION $SERVICE_VERSION

RUN useradd -ms /bin/bash app && \
    mkdir -p /app/greeter && chown app -R /app

USER app
WORKDIR /app

ADD requirements.txt setup.py ./
ADD greeter ./greeter

RUN pip install -r requirements.txt && \
    pip install .

CMD ["/bin/bash", "-c", "python3 -m gunicorn -w 8 -k uvicorn.workers.UvicornWorker -b 0.0.0.0:8000 -u app greeter.api:app"]
