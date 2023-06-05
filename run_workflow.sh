#!/bin/bash

# Check if the Python script parameter is provided
if [ -z "$1" ]; then
  echo "Please provide filename of the Python workflow file."
  exit 1
fi

# Check if the Python script exists
if [ ! -f "./src/$1" ]; then
  echo "Python script does not exist."
  exit 1
fi

# build and push image
docker login --username=$GH_WRITE_PACKAGE_USER --password=$GH_WRITE_PACKAGE ghcr.io
docker buildx build --platform linux/amd64 -t ghcr.io/aiknow-public/hera-blueprint:$USER src/main
docker push ghcr.io/aiknow-public/hera-blueprint:$USER

# run workflow
export TASK_IMAGE="ghcr.io/aiknow-public/hera-blueprint:$USER"
python "./src/$1"