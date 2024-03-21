
After installing the NFD Operator, you can move forward with installing the NVIDIA GPU operator.

On the left hand menu, navigate to **Operators --> OperatorHub** and then search of the NVIDIA GPU Operator:

![nv_operator1](../images/ai_nvidia_operator1.png)

The next screen is purely informational, explaining a bit about the operator itself. There are no options on this page, so after you are done reading you can click the **Install** button:

![nv_operator2](../images/ai_nvidia_operator2.png)

NVIDIA currently recommends having a **Manual** installPlan Approval for the subscriptions. By default the **Automatic** option is selected. 

You can pick the update channel based on the needs in your cluster.

Finally, by default, the operator will be installed into the `nvidia-gpu-operator` namespace. If the namespace is not present, it will be created for you during this process:

![nv_operator3](../images/ai_nvidia_operator3.png)

> [!IMPORTANT]
> While it is possible to use a different namespace, namespace monitoring will _not_ be enabled by default. You can enable monitoring with the following:
> `oc label ns/$NAMESPACE_NAME openshift.io/cluster-monitoring=true`

If you have chosen the manual approval process, you will need to approve the installation before continuing:

![nv_operator4](../images/ai_nvidia_operator4.png)

After the NVIDIA GPU Operator has been successfully installed, you will need to create a ClusterPolicy. This policy includes things like NVIDIA license information (if required), which options are enabled, what repos are used etc.

![nv_operator5](../images/ai_nvidia_operator5.png)

It is safe to take the defaults on the policy screen. [NVIDIA's Documentation](https://docs.nvidia.com/datacenter/cloud-native/openshift/23.9.2/install-gpu-ocp.html#create-the-cluster-policy-using-the-web-console) indicate that the defaults are sufficient for the vast majority of usecases. More advanced users are welcome to explore the options laid out in either the **Form View** or the **YAML View** before creating the policy.

![nv_operator6](../images/ai_nvidia_operator6.png)

After some time you can navigate to **Workloads --> Pods** on the left hand menu. Ensure that the `nvidia-gpu-operator` project is selected from the drop down. You should see 20 or more pods running in the cluster as seen below:

![nv_operator7](../images/ai_nvidia_operator7.png)




