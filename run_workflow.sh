#!/bin/bash

# Function to display the help message
display_help() {
  echo "Usage: ./script.sh [OPTIONS] FILENAME"
  echo "Options:"
  echo "  -f, --filename FILENAME        Specify the filename of the Python workflow file"
  echo "  -m, --measure                  Enable measurement"
  echo "  -h, --help                     Display this help message"
}

# Function to check if a command-line tool is installed
check_tool_installed() {
  command -v "$1" >/dev/null 2>&1 || { echo >&2 "Error: $1 is required but not installed. Aborting."; exit 1; }
}

# Function to check if the Python script exists
check_python_script() {
  if [ ! -f "./src/$1" ]; then
    echo "Python script does not exist."
    exit 1
  fi
}

# Function to get the pull request number created by the user
get_pull_request() {
  # Check if the required tools are installed
  check_tool_installed "gh"
  check_tool_installed "jq"

  # Set the 'user' variable if not provided
  if [ -z "$GITHUB_USER" ]; then
    echo "ERROR: GitHub username is not provided. Please set the GITHUB_USER environmental variable."
    exit 1
  fi

  pr=$(gh pr list --base "main" --author "$GITHUB_USER" --json number --state all --limit 1 | jq -r '.[].number')
}

# Function to start the execution timer
start_timer() {
  timer_start=$(date +%s.%N)
}

# Function to stop the execution timer and append result to CSV
stop_timer() {
  timer_end=$(date +%s.%N)
  execution_time=$(echo "$timer_end - $timer_start" | bc)
  if [ "$MEASURE" = true ]; then
    echo "$1, $execution_time" >> execution_times.csv
    echo "Execution time for $1: $execution_time seconds. Result appended to execution_times.csv."
  fi
}

#####
# check command line parameters and env vars
#####

# Check if the required tools are installed
check_tool_installed "argo"

# Check if the Argo server can be reached
if ! argo list >/dev/null 2>&1; then
  echo "ERROR: Unable to reach the Argo server. Make sure Argo is running and properly configured."
  exit 1
fi

# Set default values
MEASURE=false

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -f|--filename)
      FILENAME="$2"
      shift 2
      ;;
    -m|--measure)
      MEASURE=true
      shift
      ;;
    -h|--help)
      display_help
      exit
      ;;
    *)
      echo "Unknown option: $1"
      display_help
      exit 1
      ;;
  esac
done

# Load environment variables from .env file
if [[ -f .env ]]; then
  source .env
fi

# Check if the FILENAME parameter is provided
if [ -z "$FILENAME" ]; then
  echo "ERROR: Please provide the filename of the Python workflow file using the -f/--filename option."
  exit 1
fi

# Check if the Python script exists
check_python_script "$FILENAME"

# Check if the GITHUB_USER environmental variable is set
if [ -z "$GITHUB_USER" ]; then
  echo "ERROR: GitHub username is not provided. Please set the GITHUB_USER environmental variable."
  exit 1
fi

# Check if the PR_NUMBER environmental variable is set, otherwise try to get existing pull request
if [ -z "$PR_NUMBER" ]; then
  get_pull_request
  if [ -z "$pr" ]; then
    echo "ERROR: Please open a pull request first or set the PR_NUMBER environmental variable."
    exit 1
  fi
fi

# Check if the DOCKER_REGISTRY environmental variable is set
if [ -z "$DOCKER_REGISTRY" ]; then
  echo "ERROR: Docker registry is not provided. Set the DOCKER_REGISTRY environmental variable."
  exit 1
fi

# Check if the DOCKER_USER environmental variable is set
if [ -z "$DOCKER_USER" ]; then
  echo "ERROR: Docker username is not provided. Set the DOCKER_USER environmental variable."
  exit 1
fi

# Check if the DOCKER_PASSWORD environmental variable is set
if [ -z "$DOCKER_PASSWORD" ]; then
  echo "ERROR: Docker user password is not provided. Set the DOCKER_PASSWORD environmental variable."
  exit 1
fi

# Check if the DOCKER_ORGANIZATION environmental variable is set
if [ -z "$DOCKER_ORGANIZATION" ]; then
  echo "ERROR: Docker organization is not provided. Set the DOCKER_ORGANIZATION environmental variable."
  exit 1
fi

# Check if the GITHUB_REPOSITORY environmental variable is set
if [ -z "$GITHUB_REPOSITORY" ]; then
  echo "ERROR: GitHub repository is not provided. Set the GITHUB_REPOSITORY environmental variable."
  exit 1
fi

# Run the Python script
if [ "$MEASURE" = true ]; then
  echo "Measurement enabled."
fi

######
# build and push image
######

start_timer
export TASK_IMAGE="$DOCKER_REGISTRY/$DOCKER_ORGANIZATION/$GITHUB_REPOSITORY:pr-$pr"

# Check if the user is already logged in to the Docker registry
if ! docker info --format '{{.RegistryConfig.IndexConfigs}}' | grep -q "$DOCKER_REGISTRY"; then
  docker login --username="$DOCKER_USER" --password="$DOCKER_PASSWORD" "$DOCKER_REGISTRY"
fi

docker buildx build --platform linux/amd64 -t "$TASK_IMAGE" src/main
docker push "$TASK_IMAGE"

# Check the exit status of the docker push command
push_status=$?
if [[ $push_status -ne 0 ]]; then
  echo "ERROR: Failed to push Docker image."
  exit $push_status
fi
stop_timer "Docker build and push"

#####
# run workflow
#####

start_timer
python "./src/$FILENAME"
echo "Wait for workflow to complete..."
argo wait @latest -n playground
stop_timer "Workflow execution"

# log workflow results
argo logs @latest -n playground
