import os
from hera.shared import global_config as global_config
from workflows import example_workflow_template

global_config.host = "https://"+os.getenv("ARGO_SERVER")
token = os.getenv("ARGO_TOKEN").split()[1]
global_config.token = token

example_workflow_template.getWorkflowTemplate().create_as_workflow()