The Node Feature Discovery (NFD) Operator is a prerequisite for the NVIDIA GPU Operator. 

On the left hand menu, navigate to **Operators --> OperatorHub** and then search of the Node Feature Discovery Operator:

![nfd1](../images/ai_node_feature_discovery1.png)

The next screen is purely informational, explaining a bit about the operator itself. There are no options on this page, so after you are done reading you can click the **Install** button:

![nfd2](../images/ai_node_feature_discovery2.png)

Red Hat *strongly* recommends installing the NFD Operator to `openshift-nfd`. Make sure you select **A Specific Namespace On The Cluster Option**. The option to use `openshift-nfd` should be selected for you if the specific namespace option is selected:

![nfd3](../images/ai_node_feature_discovery3.png)

After the operator is installed, you will need to create a NodeFeatureDiscovery. If you are not prompted to create one, select the NFD Operator by clicking on the left hand menu **Operators --> Installed Operators**. Select the `openshift-nfd` project from the drop down and then select Node Feature Discovery Operator. Along the top there will be a tab for NodeFeatureDiscovery. Click **Create NodeFeatureDiscovery**:

![nfd4](../images/ai_node_feature_discovery4.png)

On the creation screen, the default name for the object is `nfd-instance`. This is the preferred name if it is not auto-populated. For most users, the default options are fine. Advanced users can edit the form, or dive right into the YAML.

![nfd5](../images/ai_node_feature_discovery5.png)

> [!NOTE]
> If you experience problems with your hardware being detected, it is likely a problem with the NFD Operator configuration. There should be no white or black lists by default. However, if this object is modified incorrectly, it can prevent GPUs from being detected.

To validate that the NFD operator is working correctly, navigate to **Compute --> Nodes** and then select a node you know has a GPU in it. With the node selected, go to the details tab.

![nfd6](../images/ai_node_feature_discovery6.png)

Look for the label `nvidia.com/gpu.present=` in order to find out if the GPU has been detected.

![nfd7](../images/ai_node_feature_discovery7.png)