# Base image including dependencies
FROM python:3.11-slim as base_image
WORKDIR /work

RUN apt-get update
RUN apt install libpq-dev python3-dev -y
RUN apt install build-essential -y

ADD ./requirements.txt /work/requirements.txt
RUN pip install -r requirements.txt

# Final image
FROM base_image
ADD . /work
ENV PYTHONPATH "${PYTHONPATH}:/work"