FROM python:3-alpine

LABEL maintainer=joe@twr.io

COPY . /app
WORKDIR /app

RUN apk add --update --no-cache bind-tools ca-certificates gcc musl-dev python3-dev libffi-dev openssl-dev

RUN pip install pipenv

RUN pipenv install --system --deploy

RUN apk del gcc musl-dev python3-dev libffi-dev openssl-dev

CMD ["python", "magtape-init.py"]
