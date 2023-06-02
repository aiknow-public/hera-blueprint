# Defining base image
FROM python:3.11-slim
RUN apt-get update
RUN apt install libpq-dev python3-dev -y
RUN apt install build-essential -y
RUN pip install -r requirements.txt