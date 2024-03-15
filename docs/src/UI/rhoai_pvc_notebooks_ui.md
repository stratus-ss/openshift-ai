### UI - Storage For Notebooks
In the OpenShift AI UI you can adjust the PVC settings by navigating to Settings --> Cluster Settings --> PVC Size

![pvc_notebooks](../images/ai_notebook_default_pvc.png)

Update the PVC to the desired size, scroll all the way to the bottom and click Save.

> ![IMPORTANT]
> This change causes several pods to restart and may cause disruption to active processes. This should only be done when disruption can be tolerated.

