After installing the NFD Operator, you can move forward with installing the NVIDIA GPU operator.

See the [official NVIDIA documentation](https://docs.nvidia.com/datacenter/cloud-native/openshift/latest/steps-overview.html) for the most update version of these instructions.

> [!NOTE]
> During installation, the Driver Toolkit daemon set checks for the existence of a build-dockercfg secret for the Driver Toolkit service account. When the secret does not exist, the installation stalls.
>
>You can run the following command to determine if your cluster is affected.
> ```
> oc get configs.imageregistry.operator.openshift.io cluster -o jsonpath='{.spec.storage}{"\n"}'
> ```
> If the output from the preceding command is empty, {}, then your cluster is affected and you must configure your registry to use storage

## Verify The Tool Kit

Before proceeding with the install, insure that the ImageStream is available on your cluster:

```
oc get -n openshift is/driver-toolkit
```

## Operator Installation

### Create The Namespace

NVIDIA recommends creating `nvidia-gpu-operator` for holding the requisite objects. As such, when creating the Operator via the UI, the Red Hat defaults will create this project and use it. Create the namespace with the following YAML:

```
apiVersion: v1
kind: Namespace
metadata:
  name: nvidia-gpu-operator
```

Run the following command to create the namespace `oc apply -f nvidia-ns.yaml`

> [!IMPORTANT]
> While it is possible to use a different namespace, namespace monitoring will _not_ be enabled by default. You can enable monitoring with the following:
> `oc label ns/$NAMESPACE_NAME openshift.io/cluster-monitoring=true`

### Create The OperatorGroup

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

### Create The Subscription

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


