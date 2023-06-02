from hera.workflows import DAG, Workflow, WorkflowTemplate, script

name = "ExampleWorkflow"


@script()
def flip():
    import random

    result = "heads" if random.randint(0, 1) == 0 else "tails"
    print(result)


@script()
def heads():
    print("it was heads")


@script()
def tails():
    print("it was tails")


def workflow_content():
    with DAG(name="d") as s:
        f = flip()
        heads().on_other_result(f, "heads")
        tails().on_other_result(f, "tails")


# used for gitops deployment
with WorkflowTemplate(name=name, entrypoint="d") as wt:
    workflow_content()


# used for debugging / development
with Workflow(generate_name=name+"-", entrypoint="d", namespace="playground") as w:
    workflow_content()

