import os

from hera.host_config import set_global_host, set_global_token, set_global_namespace
from hera.shared import GlobalConfig

from workflows import example_workflow

token = os.getenv("ARGO_TOKEN").split()[1]

# configure argo server
set_global_host("https://argowf.ai-know-dev.com:443")
set_global_token(token)
set_global_namespace("playground")


example_workflow.w.create()

