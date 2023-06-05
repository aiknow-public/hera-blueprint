# build and push image
docker login --username=$GH_WRITE_PACKAGE_USER --password=$GH_WRITE_PACKAGE ghcr.io
docker buildx build --platform linux/amd64 -t ghcr.io/aiknow-public/hera-blueprint:$USER src/main
docker push ghcr.io/aiknow-public/hera-blueprint:$USER

# run workflow
export TASK_IMAGE="ghcr.io/aiknow-public/hera-blueprint:$USER"
python ./src/run_workflow.py