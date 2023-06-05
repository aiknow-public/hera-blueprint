# Hera Blueprint 
[![build base image](https://github.com/aiknow-public/hera-blueprint/actions/workflows/build-base-image.yaml/badge.svg)](https://github.com/aiknow-public/hera-blueprint/actions/workflows/build-base-image.yaml)
[![build main image and deploy to dev](https://github.com/aiknow-public/hera-blueprint/actions/workflows/build-main-image-and-deploy.yaml/badge.svg)](https://github.com/aiknow-public/hera-blueprint/actions/workflows/build-main-image-and-deploy.yaml)

Blueprint for a Hera project incl. gitops support. 
You can [use this repo as template](https://github.com/aiknow-public/hera-blueprint/generate) for your hera project.

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/aiknow-public/hera-blueprint)

## Getting started

### TL;DR
1) Create a repository using this repo here as a template
2) Open it in GitHub Codespaces
3) Copy the environmental variables from the argo server (--> User menu, Button "COPY TO CLIPBOARD")
4) Paste them into the terminal in your codespace
5) Run `./run_workflow.sh example_workflow.py`

## Folder structure
- [baseimage](baseimage)  
Contains the third party packages.  
There is a pipeline which automatically builds a docker container out of it.

- [kubernetes](kubernetes)  
Contains the rendered workflow files, deployed via gitops.

- [src/main](src/main)  
Contains the package(s) with the actual code (business logic).  
There is a pipeline which automatically builds a docker container out of it.

- [src/workflows](src/workflows)  
Contains the workflow code (DAGs or Steps).  
The actual workflows / workflow templates are created
by [run _workflow.py](src/run_workflow.py) and [render_workflows.py](src/render_workflows.py).



## Scripts
- [render_workflows.py](./src/render_workflows.py)  
Used to render the WorkflowTemplate(s) as yaml, in order to deploy them via gitops.  
(Called by github action) 

- [run_workflow.sh](./run_workflow.sh)  
Script to run a workflow for debuggin, it can be started locally or via codespaces. 
Make sure to set the required environment variables.
