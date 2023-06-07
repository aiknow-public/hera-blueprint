#!/bin/bash

# Function to display the help message
display_help() {
  echo "Usage: ./script.sh [OPTIONS] FILENAME"
  echo "Options:"
  echo "  -p, --pr PR_NUMBER             Specify the pull request number (required if not using codespaces, needed for the creation on an ephemeral branch"
  echo "  -u, --user GITHUB_USER         Specify the GitHub username (required if not using codespaces to query for PRs)"
  echo "  -r, --repository GITHUB_REPO   Specify the GitHub repository (required if not using codespaces, needed for the creation on an ephemeral branch)"
  echo "  -d, --docker-user DOCKER_USER  Specify the Docker username (required if not using codespaces, needed for the creation on an ephemeral branch)"
  echo "  -w, --docker-password DOCKER_PASSWORD"
  echo "                                 Specify the Docker user password (required if not using codespaces, needed for the creation on an ephemeral branch)"
  echo "  -m, --measure                  Enable measurement"
  echo "  -h, --help                     Display this help message"
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
  pr=$(gh pr list --base "main" --author "$user" --json number --state all --limit 1 | jq -r '.[].number')
}

# Set default values
pr=""
measurement_enabled=false
user=""
repository=""
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
    -d|--docker-user)
      docker_user="$2"
      shift 2
      ;;
    -w|--docker-password)
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

# Set the 'user' variable if not provided
if [ -z "$user" ]; then
  if [ -n "$GITHUB_USER" ]; then
    user=$GITHUB_USER
  else
    echo "GitHub username not provided."
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

# Set the 'docker_user' variable if not provided
if [ -z "$docker_user" ]; then
  if [ -n "$GH_WRITE_PACKAGE_USER" ]; then
    docker_user=$GH_WRITE_PACKAGE_USER
  else
    echo "Docker username not provided."
    exit 1
  fi
fi

# Set the 'docker_user_password' variable if not provided
if [ -z "$docker_user_password" ]; then
  if [ -n "$GH_WRITE_PACKAGE" ]; then
    docker_user_password=$GH_WRITE_PACKAGE
  else
    echo "Docker user password not provided."
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

export TASK_IMAGE="ghcr.io/$repository:pr-$pr"

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
docker login --username=$docker_user --password=$docker_user_password ghcr.io
docker buildx build --platform linux/amd64 -t $TASK_IMAGE src/main
docker push $TASK_IMAGE
stop_timer "Docker build and push"

# run workflow
start_timer
python "./src/$filename"
echo Wait for workflow to complete...
argo wait @latest -n playground
stop_timer "Workflow execution"

# log workflow results
argo logs @latest -n playground