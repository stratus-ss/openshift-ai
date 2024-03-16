- [Installing The Operators](#installing-the-operators)
  - [Installing The OpenShift AI Operator](#installing-the-openshift-pipeline-operator)
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
