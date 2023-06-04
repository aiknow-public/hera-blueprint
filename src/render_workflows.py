from src.workflows import example_workflow
from hera.workflows import WorkflowTemplate

wt_list = []

# instantiate example WorkflowTemplate
with WorkflowTemplate(name=example_workflow.name, entrypoint="d", image_pull_secrets="gh-registry", service_account_name="argo-workflow") as w1:
    example_workflow.workflow_content()
wt_list.append(w1)

# add further WorkflowTemplates
# ...

# render all WorkflowTemplates and create yaml files in the gitops folder
for wt in wt_list:
    with open('./kubernetes/dev/'+wt.name+'Template.yaml', 'w') as f:
        f.write(wt.to_yaml())
