from workflows import example_workflow_content
from hera.workflows import WorkflowTemplate

wt_list = []

# instantiate example WorkflowTemplate
with WorkflowTemplate(name=example_workflow_content.name, entrypoint="d", service_account_name="argo-workflow") as w1:
    example_workflow_content.workflow_content()
wt_list.append(w1)

# add further WorkflowTemplates
# ...

# render all WorkflowTemplates and create yaml files in the gitops folder
for wt in wt_list:
    with open('../kubernetes/base/'+wt.name+'Template.yaml', 'w') as f:
        f.write(wt.to_yaml())
