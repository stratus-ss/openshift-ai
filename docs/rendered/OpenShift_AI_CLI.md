- [Installing The Operators](#installing-the-operators)
  - [Installing The OpenShift AI Operator](#installing-the-openshift-pipeline-operator)
  - [Installing The NVIDIA GPU Operator](#installing-the-nvidia-gpu-operator)
    - [Node Feature Discovery](#node-feature-discovery)
    - [NVIDIA Operator](#nvidia-operator)
    - [NVIDIA Cluster Monitoring](#nvidia-cluster-monitoring)
  - [NVIDIA - Configuring Time Slicing](#nvidia---configuring-time-slicing)
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

# Installing The Operators

OpenShift AI has a single operator for the base installation. However, it is strongly recommended to install the OpenShift Pipelines operator as well to facilitate pipelines in the Data Science workflow. To that end, the below instructions will help walk you through the installation of the operators. In the `artifacts` directory of this repository, there are example YAMLs that can be used to install the operators.

## Installing The OpenShift AI Operator

#### OpenShift AI (RHODS) Operator

The OpenShift AI Operator has two objects to create before it is fully operational in the cluster:

1. The Operator Subscription
2. The Data Science Cluster

The following can be used to install version 2.7 of the OpenShift AI Operator from the `fast` channel.

> [!NOTE]
> For legacy reasons, the OpenShift AI is actually called the `rhods-operator` (Red Hat OpenShift Data Science)

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

## Installing The NVIDIA GPU Operator

### Node Feature Discovery

The Node Feature Discovery (NFD) Operator is a prerequisite for the NVIDIA GPU Operator.

The [official documentation](https://docs.openshift.com/container-platform/4.15/hardware_enablement/psap-node-feature-discovery-operator.html#install-operator-cli_node-feature-discovery-operator) outlines the process to install the Node Feature Discovery (NFD) Operator. For convenience, the steps are summarized here. However, in the event that these instructions fail to work properly, always seek out the official documentation.

#### Installation

##### Create The Namespace

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

##### Create OperatorGroup

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

##### Create The Subscription

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

#### Create NodeFeatureDiscovery Instance

Once the NFD operator has finished installing, you will need to create a NodeFeatureDiscovery instance. The below YAML is equivalent to accepting all of the default options if you were using the OpenShift web UI. While you can make alterations, none are required. The defaults are considered sane.

```
apiVersion: nfd.openshift.io/v1
kind: NodeFeatureDiscovery
metadata:
  name: nfd-instance
  namespace: openshift-nfd
spec:
  instance: ''
  operand:
    image: >-
      registry.redhat.io/openshift4/ose-node-feature-discovery:v<OCP VERSION>
    servicePort: 12000
  topologyUpdater: false
  workerConfig:
    configData: |
      core:
        sleepInterval: 60s
      sources:
        pci:
          deviceClassWhitelist:
            - "0200"
            - "03"
            - "12"
          deviceLabelFields:
            - "vendor"
```

> [!IMPORTANT]
> Replace `<OCP VERSION>` in the above YAML with the version of OpenShift you are currently running, otherwise you will get an ImagePull error.

You can create this object by running `oc apply -f nodefeaturediscovery_cr.yaml`.

Check the status by running `oc get pods -n openshift-nfd`. There should be at least one pod for each of the nodes in the cluster.

##### Validate NFD Is Working

You can look for the label `nvidia.com/gpu.present=true`. You can run the following command to show any nodes that have the NVIDIA GPU present:

```
oc get nodes -l "nvidia.com/gpu.present=true"
```

### NVIDIA Operator

After installing the NFD Operator, you can move forward with installing the NVIDIA GPU operator.

See the [official NVIDIA documentation](https://docs.nvidia.com/datacenter/cloud-native/openshift/latest/steps-overview.html) for the most update version of these instructions.

> [!NOTE]
> During installation, the Driver Toolkit daemon set checks for the existence of a build-dockercfg secret for the Driver Toolkit service account. When the secret does not exist, the installation stalls.
>
> You can run the following command to determine if your cluster is affected.
>
> ```
> oc get configs.imageregistry.operator.openshift.io cluster -o jsonpath='{.spec.storage}{"\n"}'
> ```
>
> If the output from the preceding command is empty, {}, then your cluster is affected and you must configure your registry to use storage

#### Verify The Tool Kit

Before proceeding with the install, insure that the ImageStream is available on your cluster:

```
oc get -n openshift is/driver-toolkit
```

#### Operator Installation

##### Create The Namespace

NVIDIA recommends creating `nvidia-gpu-operator` for holding the requisite objects. As such, when creating the Operator via the UI, the Red Hat defaults will create this project and use it. Create the namespace with the following YAML:

```
apiVersion: v1
kind: Namespace
metadata:
  name: nvidia-gpu-operator
```

Run the following command to create the namespace `oc apply -f nvidia-ns.yaml`

> [!IMPORTANT]
> While it is possible to use a different namespace, namespace monitoring will *not* be enabled by default. You can enable monitoring with the following:
> `oc label ns/$NAMESPACE_NAME openshift.io/cluster-monitoring=true`

##### Create The OperatorGroup

Once the namespace is created, create an OperatorGroup object:

```
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: nvidia-gpu-operator-group
  namespace: nvidia-gpu-operator
spec:
 targetNamespaces:
 - nvidia-gpu-operator
```

Running the following command will create the CR:

```
oc apply -f nvidia-og.yaml
```

##### Create The Subscription

NVIDIA currently recommends having a manual installPlan Approval for the subscriptions. In order to get the current version for the default channel (which is the current recommended channel), you can run the following:

```
CHANNEL=$(oc get packagemanifest gpu-operator-certified -n openshift-marketplace -o jsonpath='{.status.defaultChannel}')
```

Once you have the current version you can use the following commands to get the CSV required for a subscription:

```
CSV=$(oc get packagemanifests/gpu-operator-certified -n openshift-marketplace -ojson | jq -r '.status.channels[] | select(.name == "'$CHANNEL'") | .currentCSV')
```

As long as you have set the previous environment variables you can then create your subscription YAML with the following command:

```
echo "apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: gpu-operator-certified
  namespace: nvidia-gpu-operator
spec:
  channel: ${CHANNEL}
  installPlanApproval: Manual
  name: gpu-operator-certified
  source: certified-operators
  sourceNamespace: openshift-marketplace
  startingCSV: ${CSV}
" > nvidia-operator-sub.yaml
```

This should create the YAML with the correct values intact. You can create this object by running `oc apply -f nvidia-operator-sub.yaml`. Because the approval is set to manual, you need to approve the plan before it will be installed:

```
INSTALL_PLAN=$(oc get installplan -n nvidia-gpu-operator -oname)
oc patch $INSTALL_PLAN -n nvidia-gpu-operator --type merge --patch '{"spec":{"approved":true }}'
```

After the installation of the operator is completed, a ClusterPolicy needs to be created. If you are using the environment variables as in this guide you can generate a ClusterPolicy json file with the following command

```
oc get csv -n nvidia-gpu-operator ${CSV} -ojsonpath={.metadata.annotations.alm-examples} |jq .[0] > clusterpolicy.json
```

Then simply apply the file:

```
oc apply -f clusterpolicy.json
```

> [!NOTE]
> The `clusterpolicy.json` in the `artifacts/NVIDIA_Operator` directory of this repo is for your convenience. While there is no version specific information contained within, NVIDIA may elect to change the contents of this file in the future. When in doubt, regenerate this file from the commands above.

After a short period of time you should start to see pods and daemon-sets being created in the `nvidia-gpu-operator` project by running `oc get pods,daemonset -n nvidia-gpu-operator`:

```
NAME                                                      READY   STATUS      RESTARTS   AGE
pod/gpu-feature-discovery-526k5                           1/1     Running     0          9m2s
pod/gpu-feature-discovery-8jlmt                           1/1     Running     0          9m4s
pod/gpu-operator-bf9f9fc64-29hlh                          1/1     Running     0          104m
pod/nvidia-container-toolkit-daemonset-4dg2v              1/1     Running     0          9m2s
pod/nvidia-container-toolkit-daemonset-g565d              1/1     Running     0          9m4s
pod/nvidia-cuda-validator-mrhmf                           0/1     Completed   0          5m59s
pod/nvidia-cuda-validator-v74dm                           0/1     Completed   0          5m58s
pod/nvidia-dcgm-df7cz                                     1/1     Running     0          9m4s
pod/nvidia-dcgm-exporter-b95k6                            1/1     Running     0          9m2s
pod/nvidia-dcgm-exporter-lsxq8                            1/1     Running     0          9m4s
pod/nvidia-dcgm-lhwgf                                     1/1     Running     0          9m2s
pod/nvidia-device-plugin-daemonset-d6jzv                  1/1     Running     0          9m4s
pod/nvidia-device-plugin-daemonset-hrv5z                  1/1     Running     0          9m2s
pod/nvidia-driver-daemonset-412.86.202303241612-0-7hnsp   2/2     Running     0          9m16s
pod/nvidia-driver-daemonset-412.86.202303241612-0-qtvrw   2/2     Running     0          9m19s
pod/nvidia-node-status-exporter-9nh4v                     1/1     Running     0          9m16s
pod/nvidia-node-status-exporter-tbtfx                     1/1     Running     0          9m19s
pod/nvidia-operator-validator-7zm8r                       1/1     Running     0          9m4s
pod/nvidia-operator-validator-qt9x2                       1/1     Running     0          9m2s

NAME                                                           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                                                                                                         AGE
daemonset.apps/gpu-feature-discovery                           2         2         2       2            2           nvidia.com/gpu.deploy.gpu-feature-discovery=true                                                                      46m
daemonset.apps/nvidia-container-toolkit-daemonset              2         2         2       2            2           nvidia.com/gpu.deploy.container-toolkit=true                                                                          46m
daemonset.apps/nvidia-dcgm                                     2         2         2       2            2           nvidia.com/gpu.deploy.dcgm=true                                                                                       46m
daemonset.apps/nvidia-dcgm-exporter                            2         2         2       2            2           nvidia.com/gpu.deploy.dcgm-exporter=true                                                                              46m
daemonset.apps/nvidia-device-plugin-daemonset                  2         2         2       2            2           nvidia.com/gpu.deploy.device-plugin=true                                                                              46m
daemonset.apps/nvidia-driver-daemonset-412.86.202303241612-0   2         2         2       2            2           feature.node.kubernetes.io/system-os_release.OSTREE_VERSION=412.86.202303241612-0,nvidia.com/gpu.deploy.driver=true   46m
daemonset.apps/nvidia-mig-manager                              0         0         0       0            0           nvidia.com/gpu.deploy.mig-manager=true                                                                                46m
daemonset.apps/nvidia-node-status-exporter                     2         2         2       2            2           nvidia.com/gpu.deploy.node-status-exporter=true                                                                       46m
daemonset.apps/nvidia-operator-validator                       2         2         2       2            2           nvidia.com/gpu.deploy.operator-validator=true                                                                         46m
```

### NVIDIA Cluster Monitoring

The GPU Operator generates GPU performance metrics (DCGM-export), status metrics (node-status-exporter) and node-status alerts. For OpenShift Prometheus to collect these metrics, the namespace hosting the GPU Operator must have the label `openshift.io/cluster-monitoring=true`.

By default, monitoring will be enabled on the `nvidia-gpu-operator` namespace. This is the default namespace that is recommended to install the NVIDIA objects into.

> [!NOTE]
> If you are using a non-default project name you need to run
>
> ```
> oc label ns/$NAMESPACE openshift.io/cluster-monitoring=true
> ```
>
> in order to enable cluster monitoring.

#### Enabling Monitoring Dashboard

To enable the monitoring dashboard in the OpenShift UI, you first need to get the appropriate object definition. The JSON file is too large to be included directly in the body of this text. However, it can be found in the `artifacts/NVIDIA_Operator` directory. This is provided for convenience and NVIDIA may choose to update this file. Always grab the latest version of this file when in doubt:

```
curl -LfO https://github.com/NVIDIA/dcgm-exporter/raw/main/grafana/dcgm-exporter-dashboard.json
```

After downloading the file, you need to create a configmap from the file:

```
oc create configmap nvidia-dcgm-exporter-dashboard -n openshift-config-managed --from-file=dcgm-exporter-dashboard.json
```

> [!IMPORTANT]
> The dashboard is not exposted via ANY view in the OpenShift UI by default. You can choose to enable this view in both the Administrator and Developer OpenShift Views if you so choose.

To enable the dashboard in the Administrator view in the OpenShift Web UI run the following:

```
oc label configmap nvidia-dcgm-exporter-dashboard -n openshift-config-managed "console.openshift.io/dashboard=true"
```

To enable the dashboard for the developer view as well run the following command:

```
oc label configmap nvidia-dcgm-exporter-dashboard -n openshift-config-managed "console.openshift.io/odc-dashboard=true"
```

## NVIDIA - Configuring Time Slicing

There are 3 options when it comes to sharing GPU resources amongst several tasks:
1. Multi-Instance GPU (MIG) which is only available in A100 or A30 GPU
2. Multi-Process Service (MPS)
3. Time Slicing

> [!NOTE]
> MPS support for the `k8s-device-plugin` was only introduced mid-March 2024. As such, may not be available in your version of OpenShift. As of this writing, no version of OpenShift supports MPS in the NVIDIA GPU Operator.

For most NVIDIA cards time slicing is currently the only option on OpenShift (aside from the aforementioned A100 or A30 cards).

### Setting The `device-plugin-config`

The `device-plugin-config` tells the cluster which GPU configurations are available in your cluster. As such, this file cannot be generically applied. In general, the header in the `data:` section of the configmap needs to match the model number of the GPU you wish to configure. NVIDIA provides the following example:

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: device-plugin-config
  namespace: nvidia-gpu-operator
data:
  A100-SXM4-40GB: |-
    version: v1
    sharing:
      timeSlicing:
        resources:
          - name: nvidia.com/gpu
            replicas: 8
  A100-SXM4-80GB: |-
    version: v1
    sharing:
      timeSlicing:
        resources:
          - name: nvidia.com/gpu
            replicas: 8
  Tesla-T4: |-
    version: v1
    sharing:
      timeSlicing:
        resources:
          - name: nvidia.com/gpu
            replicas: 8
```

> [!NOTE]
> The failRequestsGreaterThanOne flag is meant to help users understand this subtlety, by treating a request of 1 as an access request rather than an exclusive resource request. NVIDIA recommends setting `failRequestsGreaterThanOne=true`, but it is set to false by default. See the `time-slicing-full-example.yaml` in the `artifacts/NVIDIA_Operator` directory of this repo for proper placement.

For this simple example we will use a single card configuration:

```
kind: ConfigMap
apiVersion: v1
metadata:
  name: time-slicing-config
  namespace: nvidia-gpu-operator
data:
  Tesla-V100-SXM22: |-
    version: v1
    sharing:
      timeSlicing:
        resources:
        - name: nvidia.com/gpu
          replicas: 4

```

> [!NOTE]
> There is a difference between NVIDIA's official documentation and Red Hat's in terms of the name of the configMap. NVIDIA uses the name `device-plugin-config` while Red Hat's documentation uses `time-slicing-config`. Whichever name you use, ensure the correct references are used throughout the configurations used.

> [!IMPORTANT]
> There is no memory or fault-isolation between replicas for time-slicing! Under the hood, Compute Unified Device Architecture (CUDA) time-slicing is used to multiplex workloads from replicas of the same underlying GPU.

Once you are satisfied with the configuration for you cluster, create the configMap object with the following command:

```
oc create -f device-plugin-config.yaml
```

#### Updating The ClusterPolicy

The ClusterPolicy created earlier can be updated with an `oc patch` command:

```
oc patch clusterpolicy gpu-cluster-policy     -n nvidia-gpu-operator --type merge     -p '{"spec": {"devicePlugin": {"config": {"name": "time-slicing-config", "default":"tesla-v100-sxm2"}}}}'
```

> [!NOTE]
> The `oc patch` command above denotes a default `devicePlugin` config. This will apply the configuration, in this case time slicing, to all nodes which have a `tesla-v100-sxm2` installed. Working in combination with the NFD, this will apply time slicing instead of having to label nodes individually. If you wish to follow omit the default, simply remove `"default":tesla-v100-sxm2"` from the patch command.

#### Labeling Nodes

In order for the ClusterPolicy to apply to specific nodes, you will need to label them appropriately. You might choose to label individual nodes in the event that you have different GPUs available in the same cluster or you only want to apply time slicing to specific GPUs hosted by specific nodes.

You may want to override a nodes' label in order to apply a specific type of configuration. In this case running the following command will apply a label denoting a Tesla V100 GPU:

```
oc label --overwrite node nvidia.com/device-plugin.config=Tesla-V100-SXM2
```

After a minute or so you can verify that the nodes now have the appropriate status:

```
oc get node --selector=nvidia.com/gpu.product=Tesla-V100-SXM2-16GB-SHARED -o json | jq '.items[0].status.capacity'
```

> [!NOTE]
> A `-SHARED` suffix has been applied to the node label to indicate that time slicing has been enabled. This can be disabled in the original configMap by setting `data.${GPU}.sharing.timeSlicing.renameByDefault=false`

The output may look similar to this:

```
{
  "attachable-volumes-aws-ebs": "39",
  "cpu": "8",
  "ephemeral-storage": "104322028Ki",
  "hugepages-1Gi": "0",
  "hugepages-2Mi": "0",
  "memory": "62850120Ki",
  "nvidia.com/gpu": "4",
  "pods": "250"
}
```

The `"nvidia.com/gpu": "4"` indicates that 4 replicas are available for CUDA allocation.

To validate that configurations have been applied appropriately you can look for the `gfd` label:

```
oc get node --selector=nvidia.com/gpu.product=Tesla-V100-SXM2-16GB-SHARED -o json  | jq '.items[0].metadata.labels' | grep gfd
```

#### MachineSets

If you are running on a virtual platform with the ability to attach GPUs, you can edit the MachineSet to ensure that the `nvidia.com/device-plugin.config` is automatically applied to new machines. The following patch command will updated your MachineSet

```
oc patch machineset ${MACHINE_SET} \
    -n openshift-machine-api --type merge \
    --patch '{"spec": {"template": {"spec": {"metadata": {"labels": {"nvidia.com/device-plugin.config": "Tesla-V100-SXM2"}}}}}}'
```

## Installing The OpenShift Pipeline Operator

#### OpenShift AI (RHODS) Operator

The OpenShift AI Operator has two objects to create before it is fully operational in the cluster:

1. The Operator Subscription
2. The Data Science Cluster

The following can be used to install version 2.7 of the OpenShift AI Operator from the `fast` channel.

> [!NOTE]
> For legacy reasons, the OpenShift AI is actually called the `rhods-operator` (Red Hat OpenShift Data Science)

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

# Workbench Basics

## Creating A Workbench

In order to organize models, notebook images and other OpenShift AI artifacts you need to create a workbench. Workbenches are created in the context of distinct Data Science Projects.

## Setting Up A Workbench

### CLI - Workbench Setup

If you are looking to create a Workbench and associated artifacts there are 5 components that will need to be created:

1. The Data Science Project
2. The Persistent Volume Claim for MariaDB
3. The Data Connection
4. The Appropriate Role Binding
5. The Workbench object itself (also known as `notebook`)

The required YAML is found below. These will have to be adjusted to suite your environment.

#### The Data Science Project

The following YAML is fairly straight forward. Ensure that you replace the placeholds with appropriate values

```
apiVersion: v1
kind: Namespace
metadata:
  annotations:
    openshift.io/description: "data-science-project for <PROJECT>"
    openshift.io/display-name: "<PROJECT>"
  labels:
    kubernetes.io/metadata.name: <PROJECT>
    modelmesh-enabled: "true"
    opendatahub.io/dashboard: "true"
  name: <PROJECT>
```

After creating this file, simply run `oc apply -f workbench_namespace.yaml`

#### The Persistent Volume Claim

> [!IMPORTANT]
> The following assumes that you have dynamic storage that will create the appropriate persistent volume once a claim is registered. If not you will need to create a corresponding Persistent Volume to provide storage for the Claim

```
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  annotations:
    openshift.io/description: "Storage for <WORKBENCH_NAME>" 
    openshift.io/display-name: <WORKBENCH_NAME>
  name: <WORKBENCH_NAME>
  namespace: <PROJECT>
  finalizers:
    - kubernetes.io/pvc-protection
  labels:
    opendatahub.io/dashboard: 'true'
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
  volumeMode: Filesystem

```

Again use `oc apply -f workbench_pvc.yaml` to create the storage for the workbench.

#### The Data Connection

Assuming you are using S3 compatible storage, the following secret will enable your workbench to use Object Storage:

```
kind: Secret
apiVersion: v1
metadata:
  name: <DATACONNECTION_NAME>
  namespace: <PROJECT>
  labels:
    opendatahub.io/dashboard: 'true'
    opendatahub.io/managed: 'true'
  annotations:
    opendatahub.io/connection-type: s3
    openshift.io/display-name: <DATACONNECTION_NAME>
stringData:
  AWS_ACCESS_KEY_ID: <ACCESS_KEY>
  AWS_DEFAULT_REGION: <REGION>
  AWS_S3_BUCKET: <BUCKET_NAME>
  AWS_S3_ENDPOINT: <HTTP_ENDPOINT>:<PORT>
  AWS_SECRET_ACCESS_KEY: <SECRET_KEY>
type: Opaque
```

> [!IMPORTANT]
> The endpoint should be an `http` or `https` endpoint and include a port if appropriate. For example `AWS_S3_ENDPOINT: http://192.168.11.11:9000`.

Again use `oc apply -f workbench_dataconnection.yaml` to create the Obejct Storage for the workbench.

#### The Role Binding

The following role binding gives the `admin` role to the specified user or group. When creating the workbench via the OpenShift AI user interface, the default is to create this role binding and apply it to the user who creates the workbench. It may be desirable to have the following YAML apply to a group instead of an individual

```
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  labels:
    opendatahub.io/dashboard: "true"
    opendatahub.io/project-sharing: "true"
  name: rhods-rb-<WORKBENCH_NAME>
  namespace: <PROJECT>
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: <USER/GROUP>
  name: <GROUP/USERNAME>
```

> [!NOTE]
> The above `kind` can be either `User` or `Group`. Chose wisely according to your company's security policy.

#### The Workbench

This YAML is large. It sets things like the callback URLs, the OAUTH, notebook arguments, image type, secret references and so on. In an OpenShift cluster running `oc get workbench -A` will not yield any results. Instead the object that makes up the majority of the Workbench configuration is inside of the `Notebook` object. Thus running `oc get notebook` will return a list of the Workbenches available in the Data Science Project.

```
apiVersion: kubeflow.org/v1
kind: Notebook
metadata:
  annotations:
    notebooks.opendatahub.io/inject-oauth: "true"
    notebooks.opendatahub.io/last-image-selection: s2i-generic-data-science-notebook:2023.2
    notebooks.opendatahub.io/last-size-selection: Small
    notebooks.opendatahub.io/oauth-logout-url: https://rhods-dashboard-redhat-ods-applications.<CLUSTER_URL>/projects/<PROJECT>?notebookLogout=<WORKBENCH_NAME>
    opendatahub.io/accelerator-name: ""
    opendatahub.io/image-display-name: Standard Data Science
    openshift.io/description: <WORKBENCH_NAME>
    openshift.io/display-name: <WORKBENCH_NAME>
    backstage.io/kubernetes-id: <WORKBENCH_NAME>
  generation: 1
  labels:
    app: <WORKBENCH_NAME>
    opendatahub.io/dashboard: "true"
    opendatahub.io/odh-managed: "true"
  name: <WORKBENCH_NAME>
  namespace: <PROJECT>
spec:
  template:
    spec:
      affinity: {}
      containers:
      - env:
        - name: NOTEBOOK_ARGS
          value: |-
            --ServerApp.port=8888
                              --ServerApp.token=''
                              --ServerApp.password=''
                              --ServerApp.base_url=/notebook/<PROJECT>/<WORKBENCH_NAME>
                              --ServerApp.quit_button=False
                              --ServerApp.tornado_settings={"user":"stratus","hub_host":"https://rhods-dashboard-redhat-ods-applications.<CLUSTER_URL>","hub_prefix":"/projects/<PROJECT>"}
        - name: JUPYTER_IMAGE
          value: <full url to image in OpenShift Registry>
        envFrom:
        - secretRef:
            name: <data connection secret name>
        image: <full url to image in OpenShift Registry>
        imagePullPolicy: Always
        livenessProbe:
          failureThreshold: 3
          httpGet:
            path: /notebook/<PROJECT>/<WORKBENCH_NAME>/api
            port: notebook-port
            scheme: HTTP
          initialDelaySeconds: 10
          periodSeconds: 5
          successThreshold: 1
          timeoutSeconds: 1
        name: <WORKBENCH_NAME>
        ports:
        - containerPort: 8888
          name: notebook-port
          protocol: TCP
        readinessProbe:
          failureThreshold: 3
          httpGet:
            path: /notebook/<PROJECT>/<WORKBENCH_NAME>/api
            port: notebook-port
            scheme: HTTP
          initialDelaySeconds: 10
          periodSeconds: 5
          successThreshold: 1
          timeoutSeconds: 1
        resources:
          limits:
            cpu: "2"
            memory: 8Gi
          requests:
            cpu: "1"
            memory: 8Gi
        volumeMounts:
        - mountPath: /opt/app-root/src
          name: <WORKBENCH_NAME>
        - mountPath: /dev/shm
          name: shm
        workingDir: /opt/app-root/src
      - args:
        - --provider=openshift
        - --https-address=:8443
        - --http-address=
        - --openshift-service-account=<WORKBENCH_NAME>
        - --cookie-secret-file=/etc/oauth/config/cookie_secret
        - --cookie-expire=24h0m0s
        - --tls-cert=/etc/tls/private/tls.crt
        - --tls-key=/etc/tls/private/tls.key
        - --upstream=http://localhost:8888
        - --upstream-ca=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        - --email-domain=*
        - --skip-provider-button
        - --openshift-sar={"verb":"get","resource":"notebooks","resourceAPIGroup":"kubeflow.org","resourceName":"<WORKBENCH_NAME>","namespace":"$(NAMESPACE)"}
        - --logout-url=https://rhods-dashboard-redhat-ods-applications.apps.one.ocp4.x86experts.com/projects/<PROJECT>?notebookLogout=<WORKBENCH_NAME>
        env:
        - name: NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        image: registry.redhat.io/openshift4/ose-oauth-proxy@sha256:4bef31eb993feb6f1096b51b4876c65a6fb1f4401fee97fa4f4542b6b7c9bc46
        imagePullPolicy: Always
        livenessProbe:
          failureThreshold: 3
          httpGet:
            path: /oauth/healthz
            port: oauth-proxy
            scheme: HTTPS
          initialDelaySeconds: 30
          periodSeconds: 5
          successThreshold: 1
          timeoutSeconds: 1
        name: oauth-proxy
        ports:
        - containerPort: 8443
          name: oauth-proxy
          protocol: TCP
        readinessProbe:
          failureThreshold: 3
          httpGet:
            path: /oauth/healthz
            port: oauth-proxy
            scheme: HTTPS
          initialDelaySeconds: 5
          periodSeconds: 5
          successThreshold: 1
          timeoutSeconds: 1
        resources:
          limits:
            cpu: 100m
            memory: 64Mi
          requests:
            cpu: 100m
            memory: 64Mi
        volumeMounts:
        - mountPath: /etc/oauth/config
          name: oauth-config
        - mountPath: /etc/tls/private
          name: tls-certificates
      enableServiceLinks: false
      serviceAccountName: <WORKBENCH_NAME>
      volumes:
      - name: <WORKBENCH_NAME>
        persistentVolumeClaim:
          claimName: <WORKBENCH_NAME>
      - emptyDir:
          medium: Memory
        name: shm
      - name: oauth-config
        secret:
          defaultMode: 420
          secretName: <WORKBENCH_NAME>-oauth-config
      - name: tls-certificates
        secret:
          defaultMode: 420
          secretName: <WORKBENCH_NAME>-tls
```

If there is a problem with the workbench starting or being created, you can always run `oc describe notebook <notebook name>` and review the status section for clues as to where the problem may lay.

## Rolebindings

### General Explanation

OpenShift AI relies on most of the underlying mechanisms in OpenShift for controlling access to OpenShift AI. In vanilla OpenShift, you create projects which then have various security methods applied to them in order to ensure that administrators have fine-grained control over who can access which objects and with what permissions. A Data Science Project is just an OpenShift Project that has a specific label which enables it to be used with the OpenShift AI Dashboard.

### Workbench RBAC

#### Dealing With Projects

##### Enabling A Specific Project

Specifically, the label `opendatahub.io/dashboard=true` allows the project to be interacted with from the OpenShift AI Dashboard.

The below sample command will label `some-proj` for use with the Dashboard.

```
oc label namespace some-proj opendatahub.io/dashboard=true
```

Optionally, you can also add `modelmesh-enabled='true'` where applicable to further enhance a project.

##### Creating Data Science Projects

Because Data Science Projects are simply OpenShift Projects with an extra label or two, the same rules apply. Namely, by default the `self-provisioner` is assigned to the `system:authenticated` group. This means that in the default configuration, anyone who can log in to OpenShift, can create a Data Science Project. In addition, the user that creates the project will automatically become the project administrator.

##### Controlling Data Science Project Access

The process of granting access to a Data Science Project is the same as a regular OpenShift project. In general there are `view`, `edit` and `admin` roles. You would simply issue the following command:

```
oc adm policy add-role-to-group <role> <group name> -n <data science project name>
```

##### Prevent Data Science Project Creation

In order to prevent users from creating their own Data Science Project, you will need to patch the clusterrolebinding:

```
oc patch clusterrolebinding.rbac self-provisioners -p '{"subjects": null}'
```

> [!WARNING]
> This will disable all users from creating all projects in the OpenShift cluster where OpenShift AI is running

#### Controlling Access To The Dashboard Itself

Access to the Dashboard can be controlled by editing the `odh-dashboard-config` which resides in the `redhat-ods-applications` project.

You will see the following:

```
apiVersion: opendatahub.io/v1alpha
kind: OdhDashboardConfig
metadata:
  [...]
  name: odh-dashboard-config
  namespace: redhat-ods-applications
spec:
  dashboardConfig:
    [...]
  groupsConfig:
    adminGroups: rhods-admins
    allowedGroups: system:authenticated
```

Editing the `groupsConfig` will cause the operator to reconcile and update the Dashboard pods. It is also possible to create a YAML file that changes just the `groupsConfig` with the following contents:

```
apiVersion: opendatahub.io/v1alpha
kind: OdhDashboardConfig
metadata:
  name: odh-dashboard-config
  namespace: redhat-ods-applications
spec:
  groupsConfig:
    allowedGroups: "system:authenticated"
```

You can then apply the changes by using `oc apply -f <myfile>.yaml`

> [!IMPORTANT]
> If you want to specify a list of groups, they need to be comma separated:
>
> ```
> spec:
>  groupsConfig:
>    allowedGroups: "system:authenticated,rhods-users"
> ```

Alternatively you can use a command similar to the following to patch in your changes:

```
oc patch odhdashboardconfig/odh-dashboard-config -p '{"spec":{"groupsConfig": {"allowedGroups":"rhods-users"}}}' --type merge
```

You can follow the same process for editing the `adminGroups` instead of the `allowedGroups`. This group specifies which group of users will have admin access to the OpenShift AI Dashboard

## Default PVC For Notebookes

### Setting PVCs For Jupyter Notebooks

It is often desirable to adjust the default amount of storage provided to a Jupyter Notebook in order to accommodate the standard workloads your organization may wish to deploy. By default OpenShift AI will allocate 20G with of disk space to every Jupyter Notebook that is created.

### Workbench PVC

##### CLI - Storage For Notebooks

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

## Dealing With Idle Notebooks

### Stopping Idle Notebooks

You can reduce resource usage in your OpenShift AI deployment by stopping notebook servers that have had no user logged in for some time. By default, idle notebooks are not stopped automatically.

### Workbench Idle Notebooks

##### CLI - Stopping Notebooks

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

## Creating A Pipeline Server

Before you can successfully create a pipeline in OpenShift AI, you must configure a pipeline server. This process is very straight forward. You need to have
1. A Workbench
2. Cluster storage for the workbench
3. A Data Connection

### Pipeline Servers

#### CLI - Pipeline Server

In order to create a Pipeline server via the CLI a new object called `DataSciencePipelinesApplication` needs to be created in the Data Science Project. This file requires some adjusting for your specific environment.

```
apiVersion: datasciencepipelinesapplications.opendatahub.io/v1alpha1
kind: DataSciencePipelinesApplication
metadata:
  name: pipelines-definition
spec:
  apiServer:
    applyTektonCustomResource: true
    archiveLogs: false
    autoUpdatePipelineDefaultVersion: true
    collectMetrics: true
    dbConfigConMaxLifetimeSec: 120
    deploy: true
    enableOauth: true
    enableSamplePipeline: false
    injectDefaultScript: true
    stripEOF: true
    terminateStatus: Cancelled
    trackArtifacts: true
  database:
    disableHealthCheck: false
    mariaDB:
      deploy: true
      pipelineDBName: mlpipeline
      pvcSize: <CHANGE_ME>
      username: mlpipeline
  mlmd:
    deploy: false
  objectStorage:
    disableHealthCheck: false
    externalStorage:
      bucket: <CHANGE_ME>
      host: <CHANGE_ME>
      port: ""
      s3CredentialsSecret:
        accessKey: AWS_ACCESS_KEY_ID
        secretKey: AWS_SECRET_ACCESS_KEY
        secretName: <CHANGE_ME>
      scheme: http
  persistenceAgent:
    deploy: true
    numWorkers: 2
  scheduledWorkflow:
    cronScheduleTimezone: UTC
    deploy: true
```

In the above file the `pvcSize` by default is set to 10Gi, though this can be changed by altering this value. In addition, the Pipeline Server expects to have access to S3 compatible Object Storage. In the above example, the `secretName` is based on the Data Connection created earlier. OpenShift will prefix the name of the secret with the type of connection. In this case, the name of the storage is `dev-storage` so the secret is called `aws-connection-dev-storage`. Thus you would put `secretName: aws-connection-dev-storage` in the above YAML.

Once the above object is created in the project, you can check the status by running `oc describe dspa`. After a few minutes, the pods will have finished deploying and the cluster is ready to import Pipelines.
