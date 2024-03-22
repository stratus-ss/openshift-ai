There are 3 options when it comes to sharing GPU resources amongst several tasks:
1. Multi-Instance GPU (MIG) which is only available in A100 or A30 GPU
2. Multi-Process Service (MPS)
3. Time Slicing

> [!NOTE]
> MPS support for the `k8s-device-plugin` was only introduced mid-March 2024. As such, may not be available in your version of OpenShift. As of this writing, no version of OpenShift supports MPS in the NVIDIA GPU Operator.

For most NVIDIA cards time slicing is currently the only option on OpenShift (aside from the aforementioned A100 or A30 cards).

## Setting The `device-plugin-config` ConfigMap

The `device-plugin-config` tells the cluster which GPU configurations are available in your cluster. As such, this file cannot be generically applied. In general, the header in the `data:` section of the configmap needs to match the model number of the GPU you wish to configure.

After the NVIDIA GPU Operator is installed, navigate to **Workloads --> ConfigMaps --> Create ConfigMap**:

![ts-cm1](../images/ai_nvidia_ts_cm1.png)

There is a sample ConfigMap with multiple GPUs configured as an example in the `artifacts/time_slicing/time-slicing-full-example.yaml`. However, a base configuration for the V100 is seen below:

![ts-cm2](../images/ai_nvidia_ts_cm2.png)

> [!NOTE]
> There is a difference between NVIDIA's official documentation and Red Hat's in terms of the name of the configMap. NVIDIA uses the name `device-plugin-config` while Red Hat's documentation uses `time-slicing-config`. Whichever name you use, ensure the correct references are used throughout the configurations used.

> [!IMPORTANT]
> There is no memory or fault-isolation between replicas for time-slicing! Under the hood, Compute Unified Device Architecture (CUDA) time-slicing is used to multiplex workloads from replicas of the same underlying GPU.

Once you are satisfied, save your ConfigMap.

## Edit Cluster Policy

Next, in order to enable time slicing, you need to adjust the ClusterPolicy to indicate the ConfigMap that was just created.

Navigate to **Operators --> Installed Operators --> NVIDIA GPU Operator**

![ts-cp1](../images/ai_nvidia_ts_cp1.png)

Enabling the Time Slicing requires editing the ClusterPolicy. Select the **ClusterPolicy** tab and edit the active policy:

![ts-cp2](../images/ai_nvidia_ts_cp2.png)

Under `{"spec"{"devicePlugin":{Config"}}}` under the `name` section, add the name of the ConfigMap. You can optionally set the `default` section to the name of your desired GPU.

> [!NOTE]
> Setting the `default` section will apply the configuration, in this case time slicing, to all nodes which have a `tesla-v100-sxm2` installed. Working in combination with the NFD, this will apply time slicing to all nodes with a V100 instead of having to label nodes individually. If you wish to follow omit the default, simply remove `"default":tesla-v100-sxm2"` from the patch command.

![ts-cp4](../images/ai_nvidia_ts_cp3.png)

## OPTIONAL: Labeling Nodes

In order for the ClusterPolicy to apply to specific nodes, you will need to label them appropriately. You might choose to label individual nodes in the event that you have different GPUs available in the same cluster or you only want to apply time slicing to specific GPUs hosted by specific nodes.

You may want to override a nodes' label in order to apply a specific type of configuration. 

Navigate to **Compute --> Nodes** and select a node you know has the video card you want to add time slicing to and click the three vertical dots and **Edit Labels**

![label1](../images/ai_label_node1.png)

Add the label that corresponds with your GPU. In this case `nvidia.com/device-plugin-config=Tesla-V100-SXM2`:

![label2](../images/ai_label_node2.png)

> [!NOTE]
> A `-SHARED` suffix has been applied to the node label to indicate that time slicing has been enabled. This can be disabled in the original configMap by setting `data.${GPU}.sharing.timeSlicing.renameByDefault=false`

## Validation of Time Slicing Config

After a few minutes, the NFD Operator in combination with the NVIDIA GPU operator will detect your changes and apply  configurations to your nodes. You can validate the time slice config in two ways. First you can examine the details of the node itself. In the `status` section you should see a `capacity` with the number of `nvidia.com/gpu` equal to the amount you specified in your time slice config.

![ts-cp4](../images/ai_nvidia_ts_cp4.png)

You can also search for nodes that have gfd labels applied to them. Click on **Home --> Search**. Under **Resources** select **Node**. Search for the label `nvidia.com/gfd.timestamp`. Any node which has successfully applied the time slicing config will be displayed below:

![gfd1](../images/ai_nvidia_ts_validate.png)