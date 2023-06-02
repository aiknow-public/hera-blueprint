import os
from hera.shared import global_config as global_config

from workflows import example_workflow
from hera.workflows import Workflow

global_config.host = "https://"+os.getenv("ARGO_HOST")
token = os.getenv("ARGO_TOKEN").split()[1]
global_config.token = token

# create example workflow in namespace "playground"
with Workflow(generate_name=example_workflow.name.lower()+"-", entrypoint="d", namespace="playground") as w:
    example_workflow.workflow_content()
w.create()
