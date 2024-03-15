### CLI - Stopping Notebooks

In the `redhat-ods-applications` project there is a `ConfigMap` that tracks the users preferences with regards to notebooks. It is called `notebook-controller-config`. You will see the appropriate headings already in the `data` section of the `ConfigMap`:

```
apiVersion: v1
kind: ConfigMap
data:
  ADD_FSGROUP: "false"
  CLUSTER_DOMAIN: cluster.local
  CULL_IDLE_TIME: "1440"
  ENABLE_CULLING: "false"
  IDLENESS_CHECK_PERIOD: "1"
  ISTIO_GATEWAY: kubeflow/kubeflow-gateway
  USE_ISTIO: "false"
```

The `CULL_IDLE_TIME` is expressed in minutes as is the `IDLENESS_CHECK_PERIOD` (which controls the polling frequency).

It is possible to update the `ConfigMap` via a command similar to the following:

```
oc patch configmap notebook-controller-config -p '{"data":{"ENABLE_CULLING":"true"}}' --type merge
```

You can also use a patch file similar to this:

```
apiVersion: v1
data:
  CULL_IDLE_TIME: "144"
  ENABLE_CULLING: "false"
  IDLENESS_CHECK_PERIOD: "1"
kind: ConfigMap
metadata:
  name: notebook-controller-config
  namespace: redhat-ods-applications
```

And then use an `oc apply` to merge the changes