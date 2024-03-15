### UI - Workbench Setup

From the OpenShift AI Web UI, click `Data Science Projects` on the left hand menu. This will list all of the current projects. You can select a current project or create a new one. Select your project:

![dsp](../images/ai_datascience_project.png)

If this is a new project, you will be greated with a blank `Components` page:

![no_components](../images/ai_no_components.png)

Click the `Create Workbench` button. The `Name`, `Image Selection` and `Cluster Storage` sections are required.

![create_workbench](../images/ai_create_workbench1.png)


> ![IMPORTANT]
> You can optionally select `Use a data connection`. If you do, you will be prompted for your Object Storage credentials. This is different from cluster storage. The workbench itself creates a MariaDB container and the cluster storage is mounted into the database container. The `Data Connection` is used for storing pipeline and other objects.

Once the information has been entered click `Create Workbench` and wait for the process to complete.

![create_wb2](../images/ai_create_workbench2.png)

