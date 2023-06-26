from workflows import example_workflow_template

wt_list = []
wt_list.append(example_workflow_template.getWorkflowTemplate())

# add further WorkflowTemplates
# ...

# render all WorkflowTemplates and create yaml files in the gitops folder
for wt in wt_list:
    with open('../kubernetes/base/'+wt.name+'Template.yaml', 'w') as f:
        f.write(wt.to_yaml())
