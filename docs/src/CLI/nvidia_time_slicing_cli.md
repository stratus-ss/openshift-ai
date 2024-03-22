There are 3 options when it comes to sharing GPU resources amongst several tasks:
1. Multi-Instance GPU (MIG) which is only available in A100 or A30 GPU
2. Multi-Process Service (MPS)
3. Time Slicing

> [!NOTE]
> MPS support for the `k8s-device-plugin` was only introduced mid-March 2024. As such, may not be available in your version of OpenShift. As of this writing, no version of OpenShift supports MPS in the NVIDIA GPU Operator.

For most NVIDIA cards time slicing is currently the only option on OpenShift (aside from the aforementioned A100 or A30 cards).

## Setting The `device-plugin-config`

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
  Tesla-V100-SXM2: |-
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

### Updating The ClusterPolicy

The ClusterPolicy created earlier can be updated with an `oc patch` command:

```
oc patch clusterpolicy gpu-cluster-policy     -n nvidia-gpu-operator --type merge     -p '{"spec": {"devicePlugin": {"config": {"name": "time-slicing-config", "default":"tesla-v100-sxm2"}}}}'
```

> [!NOTE]
> The `oc patch` command above denotes a default `devicePlugin` config. This will apply the configuration, in this case time slicing, to all nodes which have a `tesla-v100-sxm2` installed. Working in combination with the NFD, this will apply time slicing instead of having to label nodes individually. If you wish to follow omit the default, simply remove `"default":tesla-v100-sxm2"` from the patch command.

### Labeling Nodes

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

### MachineSets

If you are running on a virtual platform with the ability to attach GPUs, you can edit the MachineSet to ensure that the `nvidia.com/device-plugin.config` is automatically applied to new machines. The following patch command will updated your MachineSet

```
oc patch machineset ${MACHINE_SET} \
    -n openshift-machine-api --type merge \
    --patch '{"spec": {"template": {"spec": {"metadata": {"labels": {"nvidia.com/device-plugin.config": "Tesla-V100-SXM2"}}}}}}'
```

