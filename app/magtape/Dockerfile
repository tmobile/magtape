FROM python:3-alpine

LABEL maintainer=joe@twr.io

COPY ./Pipfile* /app/

WORKDIR /app

RUN apk add --update --no-cache bind-tools ca-certificates

RUN pip install pipenv

RUN pipenv install --system --deploy

COPY ./magtape.py /app/

CMD ["python", "magtape.py"]

