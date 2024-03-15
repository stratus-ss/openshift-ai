### CLI - Storage For Notebooks

In the `redhat-ods-applications` project the `odhdashboardconfig` contains some of the default options for the `notebookController`. Specifically:

```
    notebookController:
      enabled: true
      notebookNamespace: rhods-notebooks
      notebookTolerationSettings:
        enabled: false
        key: NotebooksOnly
      pvcSize: 5Gi
```

You can edit this with an `oc patch` command similar to the following

```
oc patch odhdashboardconfig/odh-dashboard-config -p '{"spec":{"notebookController": {"pvcSize":"6Gi"}}}' --type merge
```

Alternatively you can create a file with contents similar to this:

```
apiVersion: opendatahub.io/v1alpha
kind: OdhDashboardConfig
metadata:
  name: odh-dashboard-config
  namespace: redhat-ods-applications
spec:
  notebookController:
    pvcSize: "5Gi"
```

and then use `oc apply -f <myfile>.yaml` to apply the changes
