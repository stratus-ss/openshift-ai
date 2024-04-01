
The Notebook sizes that appear as options in the OpenShift AI dashboard are controlled by the `OdhDashboardConfig` which resides in the `redhat-ods-applications` namespace.

You can search from the OpenShift UI by filtering for the `odc` object, ensuring that the project is set to `redhat-ods-applications`:

![odc_ui1](../images/ai_odhdashboard1.png)

Under the `spec` section you will find `notebookSizes`, also represented by `"{'spec': {'notebookSizes'}}"`. This object is a list of attributes.  Red Hat recommends at least the following attributes:

```
  - name: <name>
    resources:
      limits:
        cpu: <# cpus>
        memory: <ram in Mi or Gi>
      requests:
        cpu: <# cpus>
        memory: <ram in Mi or Gi>
```

![odc_ui2](../images/ai_odhdashboard2.png)

Once this object has been edited, the operator will eventually reconcil the `rhods-dashboard-` pods. A refresh of the OpenShift AI webpage may be required.

> [!NOTE]
> If the operator is taking longer than you would like you can delete the appropriate pods with the following command:
> ```
> oc delete pods -l app=rhods-dashboard -n redhat-ods-applications
> ```