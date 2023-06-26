import os
from hera.workflows import DAG, WorkflowTemplate, script
from hera.workflows.models import ImagePullPolicy

name = "hera-example-animals"
image = os.getenv("TASK_IMAGE")

@script(
    image=image,
    image_pull_policy=ImagePullPolicy.always
)
def foo():
    from art import art
    from samplemodule import do_something

    # from own code
    do_something()

    # test external package
    art_1 = art("foo")
    print(art_1)


def getWorkflowTemplate():
    with WorkflowTemplate(
        name=name,
        namespace="playground",
        entrypoint="d",
        service_account_name="argo-workflow"
    ) as w:
        with DAG(name="d"):
            foo()
    return w