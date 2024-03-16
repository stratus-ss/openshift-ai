### OpenShift Pipeline Operator

In contrast to the OpenShift AI Operator, the Pipeline Operator only requires an appropriate subscription to become active on the cluster. The below YAML will create a Pipeline Operator that tracks the latest version available from Red Hat.

```
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  labels:
    operators.coreos.com/openshift-pipelines-operator-rh.openshift-operators: ""
  name: openshift-pipelines-operator-rh
  namespace: openshift-operators
spec:
  channel: latest
  installPlanApproval: Automatic
  name: openshift-pipelines-operator-rh
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  startingCSV: openshift-pipelines-operator-rh.v1.14.1
```

You can create this object by running `oc apply -f openshift_pipelines_sub`.