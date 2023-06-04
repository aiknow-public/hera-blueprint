# build and push image
docker buildx build --platform linux/amd64 -t ghcr.io/aiknow-public/hera-blueprint:$USER src/code
docker push ghcr.io/aiknow-public/hera-blueprint:$USER

# run workflow
export TASK_IMAGE="ghcr.io/aiknow-public/hera-blueprint:$USER"
python ./src/run_workflow.py