from hera.workflows import DAG, script
from hera.workflows.models import ImagePullPolicy

# will be used when Workflow / WorkflowTemplate is created
name = "Example"


@script(
    image="ghcr.io/aiknow-public/hera-blueprint-base:main",
    image_pull_policy=ImagePullPolicy.always
)
def flip():
    import random
    from art import art

    # test external package
    art_1 = art("foo")
    print(art_1)

    result = "heads" if random.randint(0, 1) == 0 else "tails"
    print(result)


@script()
def heads():
    print("it was the heads")


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


