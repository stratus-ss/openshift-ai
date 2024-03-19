The Node Feature Discovery (NFD) Operator is a prerequisite for the NVIDIA GPU Operator. 

The [official documentation](https://docs.openshift.com/container-platform/4.15/hardware_enablement/psap-node-feature-discovery-operator.html#install-operator-cli_node-feature-discovery-operator) outlines the process to install the Node Feature Discovery (NFD) Operator. For convenience, the steps are summarized here. However, in the event that these instructions fail to work properly, always seek out the official documentation.

## Installation

### Create The Namespace

The first requirement for the NFD operator is to create the namespace to hold the subscription and the operator group used to deploy the requisite objects.

```
apiVersion: v1
kind: Namespace
metadata:
  name: openshift-nfd
```

Create the namespace by running the following command:

```
oc create -f nfd-namespace.yaml
```

### Create OperatorGroup

After creating the namespace, use the following YAML to create the required operator group:

```
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  generateName: openshift-nfd-
  name: openshift-nfd
  namespace: openshift-nfd
spec:
  targetNamespaces:
  - openshift-nfd
```

Create the OperatorGroup by running the following command:

```
oc create -f nfd-operatorgroup.yaml
```

### Create The Subscription

Finally subscribe to the appropriate channel to complete the operator installation:

```
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: nfd
  namespace: openshift-nfd
spec:
  channel: "stable"
  installPlanApproval: Automatic
  name: nfd
  source: redhat-operators
  sourceNamespace: openshift-marketplace
```

Create the subscription object by running the following command:

```
oc create -f nfd-sub.yaml
```

After a little time pods will begin to be created in the `openshift-nfd`. 

```
oc get pods -n openshift-nfd
```

## Create NodeFeatureDiscovery Instance

Once the NFD operator has finished installing, you will need to create a NodeFeatureDiscovery instance. The below YAML is equivalent to accepting all of the default options if you were using the OpenShift web UI. While you can make alterations, none are required. The defaults are considered sane.

```
apiVersion: nfd.openshift.io/v1
kind: NodeFeatureDiscovery
metadata:
  name: nfd-instance
  namespace: openshift-nfd
spec:
  instance: "" # instance is empty by default
  topologyupdater: false # False by default
  operand:
    image: registry.redhat.io/openshift4/ose-node-feature-discovery:v<OCP VERSION>
    imagePullPolicy: Always
  workerConfig:
    configData: |
      core:
        sleepInterval: 60s
      sources:
        cpu:
          cpuid:
            attributeBlacklist:
              - "BMI1"
              - "BMI2"
              - "CLMUL"
              - "CMOV"
              - "CX16"
              - "ERMS"
              - "F16C"
              - "HTT"
              - "LZCNT"
              - "MMX"
              - "MMXEXT"
              - "NX"
              - "POPCNT"
              - "RDRAND"
              - "RDSEED"
              - "RDTSCP"
              - "SGX"
              - "SSE"
              - "SSE2"
              - "SSE3"
              - "SSE4.1"
              - "SSE4.2"
              - "SSSE3"
            attributeWhitelist:
        kernel:
          kconfigFile: "/path/to/kconfig"
          configOpts:
            - "NO_HZ"
            - "X86"
            - "DMI"
        pci:
          deviceClassWhitelist:
            - "0200"
            - "03"
            - "12"
          deviceLabelFields:
            - "class"
  customConfig:
    configData: |
          - name: "more.kernel.features"
            matchOn:
            - loadedKMod: ["example_kmod3"]
```

> [!IMPORTANT]
> Replace `<OCP VERSION>` in the above YAML with the version of OpenShift you are currently running, otherwise you will get an ImagePull error.

You can create this object by running `oc apply -f nodefeaturediscovery_cr.yaml`.

Check the status by running `oc get pods -n openshift-nfd`. There should be at least one pod for each of the nodes in the cluster.

### Validate NFD Is Working

You can look for the label `nvidia.com/gpu.present=true`. You can run the following command to show any nodes that have the NVIDIA GPU present:

```
oc get nodes -l "nvidia.com/gpu.present=true"
```
