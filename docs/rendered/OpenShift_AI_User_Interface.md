- [Installing The OpenShift AI Operator](#installing-the-openshift-pipeline-operator)
- [Installing The OpenShift Pipeline Operator](#installing-the-openshift-pipeline-operator)
- [Workbench Basics](#workbench-basics)
  - [Setting Up A Workbench](#setting-up-a-workbench)
  - [Rolebindings](#rolebindings)
    - [Workbench RBAC](#workbench-rbac)
  - [Default PVC For Notebookes](#default-pvc-for-notebookes)
    - [Workbench PVC](#workbench-pvc)
  - [Dealing With Idle Notebooks](#dealing-with-idle-notebooks)
    - [Workbench Idle Notebooks](#workbench-idle-notebooks)
  - [Creating A Pipeline Server](#creating-a-pipeline-server)
    - [Pipeline Servers](#pipeline-servers)

# Installing The OpenShift AI Operator

##blank

# Installing The OpenShift Pipeline Operator

##blank

# Workbench Basics

## Creating A Workbench

In order to organize models, notebook images and other OpenShift AI artifacts you need to create a workbench. Workbenches are created in the context of distinct Data Science Projects.

## Setting Up A Workbench

#### UI - Workbench Setup

From the OpenShift AI Web UI, click `Data Science Projects` on the left hand menu. This will list all of the current projects. You can select a current project or create a new one. Select your project:

![dsp](../images/ai_datascience_project.png)

If this is a new project, you will be greated with a blank `Components` page:

![no_components](../images/ai_no_components.png)

Click the `Create Workbench` button. The `Name`, `Image Selection` and `Cluster Storage` sections are required.

![create_workbench](../images/ai_create_workbench1.png)

> [!IMPORTANT]
> You can optionally select `Use a data connection`. If you do, you will be prompted for your Object Storage credentials. This is different from cluster storage. The workbench itself creates a MariaDB container and the cluster storage is mounted into the database container. The `Data Connection` is used for storing pipeline and other objects.

Once the information has been entered click `Create Workbench` and wait for the process to complete.

![create_wb2](../images/ai_create_workbench2.png)

## Rolebindings

### General Explanation

OpenShift AI relies on most of the underlying mechanisms in OpenShift for controlling access to OpenShift AI. In vanilla OpenShift, you create projects which then have various security methods applied to them in order to ensure that administrators have fine-grained control over who can access which objects and with what permissions. A Data Science Project is just an OpenShift Project that has a specific label which enables it to be used with the OpenShift AI Dashboard.

### Workbench RBAC

##### Using OpenShift AI's Dashboard

OpenShift AI's Dashboard is an object inside of OpenShift. By default the Dashboard will have the option to "Log in with OpenShift"

![login](../images/ai_login_with_openshift.png)

This means if you have an authentication provider configured by an OpenShift Administrator, those users and groups will be available within the OpenShift AI Dashboard. There is a distinction between users who are allowed to login to the OpenShift AI Dashboard and users who have access to various Data Science Projects.

##### UI - Controlling Access To The Dashboard Itself

There are two methods for manipulating group access. First, the OpenShift AI Dashboard (assuming the user you are logged in as has the appropriate permissions) allows administrators to select via a drop down groups:

![user_mgmt1.png](../images/ai_user_mgmt1.png).

> [!IMPORTANT]
> By default the `system:authenticated` group is selected. This allows anyone who can log into OpenShift to have access to the OpenShift AI Dashboard. This may not be what you want.

When you make a change to the user or group, the Dashboard Config object is edited for you. The operator, which resides in the project `redhat-ods-operator` will reconcile the changes made to this object after a short period of time by merging the changes with the active configuration of the containers.

##### UI - Controlling Data Science Project Access

You may wish to grant users or groups to various roles inside of a Data Science Project as well. In order to do this, select Data Science Projects --> Your Project --> Permissions:

![proj_mgmt](../images/ai_proj_mgmt1.png)

From here you can select the various roles you might have created in your OpenShift Cluster. By default the Edit and Admin options are available.

## Default PVC For Notebookes

### Setting PVCs For Jupyter Notebooks

It is often desirable to adjust the default amount of storage provided to a Jupyter Notebook in order to accommodate the standard workloads your organization may wish to deploy. By default OpenShift AI will allocate 20G with of disk space to every Jupyter Notebook that is created.

### Workbench PVC

##### UI - Storage For Notebooks

In the OpenShift AI UI you can adjust the PVC settings by navigating to Settings --> Cluster Settings --> PVC Size

![pvc_notebooks](../images/ai_notebook_default_pvc.png)

Update the PVC to the desired size, scroll all the way to the bottom and click Save.

> ![IMPORTANT]
> This change causes several pods to restart and may cause disruption to active processes. This should only be done when disruption can be tolerated.

## Dealing With Idle Notebooks

### Stopping Idle Notebooks

You can reduce resource usage in your OpenShift AI deployment by stopping notebook servers that have had no user logged in for some time. By default, idle notebooks are not stopped automatically.

### Workbench Idle Notebooks

##### UI - Stopping Notebooks

The settings related to stopping the notebook can be found under Settings --> Cluster Settings --> Stop Idle Notebooks

![ui-stopping](../images/ai_stop_idle_notebooks.png)

Simply select the timeout that matches your environment

## Creating A Pipeline Server

Before you can successfully create a pipeline in OpenShift AI, you must configure a pipeline server. This process is very straight forward. You need to have
1. A Workbench
2. Cluster storage for the workbench
3. A Data Connection

### Pipeline Servers

##### UI - Pipeline Server

In The OpenShift AI UI, navigate to `Data Science Projects --> <your project>`.

![dsp](../images/ai_datascience_project.png)

Once you have selected the desired project, you will see the requisite objects (Workbenches, Cluster Storage, Data Conenctions etc)

![pipeline_server](../images/ai_pipeline_server.png)

Select `Configure Pipeline Server`. You will be greated with the option of inputting your Data Connection details.

![pipeline_server_options](../images/ai_pipeline_server_options.png)

Alternatively, you can click the the key icon and populate the form with any Data Connection available in the project:

![pipeline_prepopulate](../images/ai_pipeline_server_options2.png)

Once this is complete, the UI will not show any pipelines. However, the `Import Pipeline` button will now be available where it was greyed out before:

![pipeline_import](../images/ai_pipeline_import.png)

At this point the cluster will have created 4 deployments in your Data Science Project

```
ds-pipeline-persistenceagent-pipelines-definition
ds-pipeline-pipelines-definition                 
ds-pipeline-scheduledworkflow-pipelines-definition
mariadb-pipelines-definition  
```

OpenShift AI is now ready to handle AI pipelines.
