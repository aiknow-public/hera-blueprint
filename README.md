# Hera Blueprint 

...

## Folder structure
### [kubernetes](kubernetes)
Contains the rendered workflow files, deployed via Gitops 

### [src](src)
Soruce code for ...

#### [src/workflows](workflows)
Contains the workflow code (DAGs or Steps)

#### [src/code](code)
Contains the package(s) with the actual code (business logic).
There is a pipeline which automatically builds a docker container out of it.

#### [src/base](base)
Contains the third party packages.
There is a pipeline which automatically builds a docker container out of it.

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