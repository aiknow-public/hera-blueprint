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

# Check if measurement parameter is provided and set the measurement flag
measurement_enabled=false
if [ "$2" == "-m" ]; then
  measurement_enabled=true
fi

# Function to start the execution timer
start_timer() {
  timer_start=$(date +%s.%N)
}

# Function to stop the execution timer and append result to CSV
stop_timer() {
  timer_end=$(date +%s.%N)
  execution_time=$(echo "$timer_end - $timer_start" | bc)
  if [ "$measurement_enabled" = true ]; then
    echo "$1, $execution_time" >> execution_times.csv
    echo "Execution time for $1: $execution_time seconds. Result appended to execution_times.csv."
  fi
}

# build and push image
start_timer
docker login --username=$GH_WRITE_PACKAGE_USER --password=$GH_WRITE_PACKAGE ghcr.io
docker buildx build --platform linux/amd64 -t ghcr.io/aiknow-public/hera-blueprint:$USER src/main
docker push ghcr.io/aiknow-public/hera-blueprint:$USER
stop_timer "Docker build and push"

# run workflow
start_timer
export TASK_IMAGE="ghcr.io/aiknow-public/hera-blueprint:$USER"
python "./src/$1"
echo Wait for workflow to complete...
argo wait @latest -n playground
stop_timer "Workflow execution"

# log workflow results
argo logs @latest -n playground