### OpenShift AI (RHODS) Operator

The OpenShift AI Operator has two objects to create before it is fully operational in the cluster:

1. The Operator Subscription
2. The Data Science Cluster

The following can be used to install version 2.7 of the OpenShift AI Operator from the `fast` channel. 
>[!NOTE]
> For legacy reasons, the OpenShift AI is actually called the `rhods-operator`  (Red Hat OpenShift Data Science)

```
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  labels:
    operators.coreos.com/rhods-operator.redhat-ods-operator: ""
  name: rhods-operator
  namespace: redhat-ods-operator
spec:
  channel: fast
  installPlanApproval: Automatic
  name: rhods-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  startingCSV: rhods-operator.2.7.0
```

You can create this object by running `oc apply -f openshift_ai_subscription.yaml`.

If you need a different channel or version you will need to update the appropriate sections of the above YAML.

After the subscription has completed, the next step is to create a Data Science Cluster. The below YAML is sufficient for the vast majority of users. Advanced users are welcome to adjust the below options as they see fit

```
apiVersion: datasciencecluster.opendatahub.io/v1
kind: DataScienceCluster
metadata:
  labels:
    app.kubernetes.io/created-by: rhods-operator
    app.kubernetes.io/instance: default-dsc
    app.kubernetes.io/managed-by: kustomize
    app.kubernetes.io/name: datasciencecluster
    app.kubernetes.io/part-of: rhods-operator
  name: default-dsc
spec:
  components:
    codeflare:
      managementState: Removed
    dashboard:
      managementState: Managed
    datasciencepipelines:
      managementState: Managed
    kserve:
      managementState: Managed
      serving:
        ingressGateway:
          certificate:
            type: SelfSigned
        managementState: Managed
        name: knative-serving
    modelmeshserving:
      managementState: Managed
    ray:
      managementState: Removed
    trustyai: {}
    workbenches:
      managementState: Managed
```

You can create this object by running `openshift_ai_datasciencecluster.yaml`
