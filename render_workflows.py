from workflows import example_workflow

with open('./kubernetes/dev/'+example_workflow.name+'Template.yaml', 'w') as f:
    f.write(example_workflow.wt.to_yaml())