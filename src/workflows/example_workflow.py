from hera.workflows import DAG, script
from hera.workflows.models import ImagePullPolicy

# will be used when Workflow / WorkflowTemplate is created
name = "Example"


@script(
    image="ghcr.io/aiknow-public/hera-blueprint:main",
    image_pull_policy=ImagePullPolicy.always
)
def foo():
    from art import art
    from tasks.some_tasks import do_something

    # from own code
    do_something()

    # test external package
    art_1 = art("foo")
    print(art_1)


def workflow_content():
    """Returns the content of the desired workflow.

    Out of this a WorkflowTemplate will be created for the deployment or a Workflow for debugging.

    :rtype: object
    """
    with DAG(name="d") as s:
        f = foo()

