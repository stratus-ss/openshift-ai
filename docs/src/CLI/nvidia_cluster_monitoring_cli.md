The GPU Operator generates GPU performance metrics (DCGM-export), status metrics (node-status-exporter) and node-status alerts. For OpenShift Prometheus to collect these metrics, the namespace hosting the GPU Operator must have the label `openshift.io/cluster-monitoring=true`.

By default, monitoring will be enabled on the `nvidia-gpu-operator` namespace. This is the default namespace that is recommended to install the NVIDIA objects into. 

> [!NOTE]
> If you are using a non-default project name you need to run
> ```
> oc label ns/$NAMESPACE openshift.io/cluster-monitoring=true
> ```
> in order to enable cluster monitoring.

## Enabling Monitoring Dashboard

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

## Enabling The NVIDIA GPU Operator Dashboard


Below you can find a summation of the [official NVIDIA documentation](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/openshift/enable-gpu-op-dashboard.html) on how to enable the GPU Operator Dashboard. This enables GPU related information in the `Cluster Utilization` section of the OpenShift Dashboard.

> [!NOTE]
> Helm is required to install these components

First, add the repo and update helm:
```
helm repo add rh-ecosystem-edge https://rh-ecosystem-edge.github.io/console-plugin-nvidia-gpu

helm update
```

Next, install the helm chart in the `nvidia-gpu-operator` namespace:

```
helm install -n nvidia-gpu-operator console-plugin-nvidia-gpu rh-ecosystem-edge/console-plugin-nvidia-gpu
```

You should see output similar to the following:

```
NAME: console-plugin-nvidia-gpu
LAST DEPLOYED: Thu Mar 14 09:35:36 2024
NAMESPACE: nvidia-gpu-operator
STATUS: deployed
REVISION: 1
```

In order to verify whether the plugin has been installed you can run the following command:

```
oc get consoles.operator.openshift.io cluster --output=jsonpath="{.spec.plugins}"
```

The output will look similar to this:

```
["kubevirt-plugin","monitoring-plugin","pipelines-console-plugin"]
```

If you don't see the `console-plugin-nvidia-gpu` in the list you can patch it in:

```
oc patch consoles.operator.openshift.io cluster --patch '[{"op": "add", "path": "/spec/plugins/-", "value": "console-plugin-nvidia-gpu" }]' --type=json
```

> [!NOTE]
> The above patch command is __NOT__ idempotent

If the plugin is shown in the output like this

```
["kubevirt-plugin","monitoring-plugin","pipelines-console-plugin","console-plugin-nvidia-gpu"]
```

You can enable it with the following patch:

```
oc patch consoles.operator.openshift.io cluster --patch '{ "spec": { "plugins": ["console-plugin-nvidia-gpu"] } }' --type=merge
```

> [!NOTE]
> The above patch __IS__ idempotent. If run multiple times it will return
> ```
> console.operator.openshift.io/cluster patched (no change)
> ```


You can view the results by opening the OpenShift Web UI and going to **Home --> Overview**. You should now have GPU related infomation:

![nvidia_dashboard](../images/nvidia_dashboard_overview.png)


> [!NOTE]
> If the plugin does not show in the dashboard, this is usually related to the user's browser session. Try using a private browsing option. If this is successful, you can try (from a normal browsing session) logging out, clearing the cache and logging back in.
