from hera.workflows import DAG, script

# will be used when Workflow / WorkflowTemplate is created
name = "Example"


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
    """Returns the content of the desired workflow.

    Out of this a WorkflowTemplate will be created for the deployment or a Workflow for debugging.

    :rtype: object
    """
    with DAG(name="d") as s:
        f = flip()
        heads().on_other_result(f, "heads")
        tails().on_other_result(f, "tails")


