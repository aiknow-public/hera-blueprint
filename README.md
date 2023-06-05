# Hera Blueprint 
[![build base image](https://github.com/aiknow-public/hera-blueprint/actions/workflows/build-base-image.yaml/badge.svg)](https://github.com/aiknow-public/hera-blueprint/actions/workflows/build-base-image.yaml)
[![build main image and deploy to dev](https://github.com/aiknow-public/hera-blueprint/actions/workflows/build-main-image-and-deploy.yaml/badge.svg)](https://github.com/aiknow-public/hera-blueprint/actions/workflows/build-main-image-and-deploy.yaml)

Blueprint for a Hera project incl. gitops support.

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
### [./render_workflows.py](./render_workflows.py)
Used to render the WorkflowTemplate(s) as yaml, in order to deploy them via gitops

### [./run_workflfow.py](./run_workflfow.py)
Sample script to run a workflow locally or via codespaces. 
Make sure to set the required environment variables (TODO docu).

## Github pipelines 
### [deploy-to-dev](.github/workflows/deploy-to-dev.yaml)
Renders the WorkflowTemplates and commits the changes to the yamls in [kubernetes/dev](kubernetes/dev).
Like this a deployment to dev is triggered on push to `main`.
