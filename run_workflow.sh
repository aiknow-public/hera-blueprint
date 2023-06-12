#!/bin/bash

# Function to display the help message
display_help() {
  echo "Usage: ./script.sh [OPTIONS] FILENAME"
  echo "Options:"
  echo "  -m, --measure                  Enable measurement"
  echo "  -h, --help                     Display this help message"
  echo ""
  echo "The following options are only needed if not working with codespaces but e.g. from local laptop:"
  echo "  -p, --pr PR_NUMBER             Specify the pull request number"
  echo "  -u, --user GITHUB_USER         Specify the GitHub username (required to query for PRs)"
  echo "  -r, --repository GITHUB_REPO   Specify the GitHub repository (including org if github registry is used)"
  echo "  -dr, --docker-registry DOCKER_REGISTRY"
  echo "                                 Specify the Docker registry"
  echo "  -du, --docker-user DOCKER_USER Specify the Docker username"
  echo "  -dp, --docker-password DOCKER_PASSWORD"
  echo "                                 Specify the Docker user password"
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
  if [ -z "$user" ]; then
    if [ -n "$GITHUB_USER" ]; then
      user=$GITHUB_USER
    else
      echo "GitHub username not provided."
      exit 1
    fi
  fi

  pr=$(gh pr list --base "main" --author "$user" --json number --state all --limit 1 | jq -r '.[].number')
}

# Check if the required tools are installed
check_tool_installed "argo"

# Set default values
pr=""
measurement_enabled=false
user=""
repository=""
docker_registry=""
docker_user=""
docker_user_password=""

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -p|--pr)
      pr="$2"
      shift 2
      ;;
    -u|--user)
      user="$2"
      shift 2
      ;;
    -r|--repository)
      repository="$2"
      shift 2
      ;;
    -dr|--docker-registry)
      docker_registry="$2"
      shift 2
      ;;
    -du|--docker-user)
      docker_user="$2"
      shift 2
      ;;
    -dp|--docker-password)
      docker_user_password="$2"
      shift 2
      ;;
    -m|--measure)
      measurement_enabled=true
      shift
      ;;
    -h|--help)
      display_help
      exit 0
      ;;
    *)
      filename=$1
      shift
      ;;
  esac
done

# Check if the Python script parameter is provided
if [ -z "$filename" ]; then
  echo "Please provide the filename of the Python workflow file."
  exit 1
fi

# Check if the Python script exists
check_python_script "$filename"

# Check if ARGO_SERVER environment variable is set
if [[ -z "$ARGO_SERVER" ]]; then
  echo "ERROR: ARGO_SERVER environment variable is not set."
  exit 1
fi

# Set the 'docker_registry' variable if not provided
if [ -z "$docker_registry" ]; then
  if [ -n "$DOCKER_REGISTRY" ]; then
    docker_registry=$DOCKER_REGISTRY
  else
    echo "Docker registry not provided."
    exit 1
  fi
fi

# Set the 'repository' variable if not provided
if [ -z "$repository" ]; then
  if [ -n "$GITHUB_REPOSITORY" ]; then
    repository=$GITHUB_REPOSITORY
  else
    echo "GitHub repository not provided."
    exit 1
  fi
fi

# Check if PR parameter is provided, otherwise try to get existing pull request
if [ -z "$pr" ]; then
  get_pull_request
  if [ -z "$pr" ]; then
    echo "Please open a pull request first."
    exit 1
  fi
fi

# Run the Python script
if [ "$measurement_enabled" = true ]; then
  echo "Measurement enabled."
fi

export TASK_IMAGE="$docker_registry/$repository:pr-$pr"

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

######
# build and push image
######
start_timer
# Check if the user is already logged in to the Docker registry
if ! docker info --format '{{.RegistryConfig.IndexConfigs}}' | grep -q "$docker_registry"; then
  # Set the 'docker_user' variable if not provided
  if [ -z "$docker_user" ]; then
    if [ -n "$DOCKER_USER" ]; then
      docker_user=$DOCKER_USER
    else
      echo "Docker username not provided."
      exit 1
    fi
  fi

  # Set the 'docker_user_password' variable if not provided
  if [ -z "$docker_user_password" ]; then
    if [ -n "$DOCKER_PASSWORD" ]; then
      docker_user_password=$DOCKER_PASSWORD
    else
      echo "Docker user password not provided."
      exit 1
    fi
  fi

  docker login --username="$docker_user" --password="$docker_user_password" "$docker_registry"
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
python "./src/$filename"
echo "Wait for workflow to complete..."
argo wait @latest -n playground
stop_timer "Workflow execution"

# log workflow results
argo logs @latest -n playground
