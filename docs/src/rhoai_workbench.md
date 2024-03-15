## Creating A Workbench

In order to organize models, notebook images and other OpenShift AI artifacts you need to create a workbench. Workbenches are created in the context of distinct Data Science Projects.

### UI - Workbench Setup

From the OpenShift AI Web UI, click `Data Science Projects` on the left hand menu. This will list all of the current projects. You can select a current project or create a new one. Select your project:

![dsp](../images/ai_datascience_project.png)

If this is a new project, you will be greated with a blank `Components` page:

![no_components](../images/ai_no_components.png)

Click the `Create Workbench` button. The `Name`, `Image Selection` and `Cluster Storage` sections are required.

![create_workbench](../images/ai_create_workbench1.png)


> ![IMPORTANT]
> You can optionally select `Use a data connection`. If you do, you will be prompted for your Object Storage credentials. This is different from cluster storage. The workbench itself creates a MariaDB container and the cluster storage is mounted into the database container. The `Data Connection` is used for storing pipeline and other objects.

Once the information has been entered click `Create Workbench` and wait for the process to complete.

![create_wb2](../images/ai_create_workbench2.png)

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

>![IMPORTANT]
>The following assumes that you have dynamic storage that will create the appropriate persistent volume once a claim is registered. If not you will need to create a corresponding Persistent Volume to provide storage for the Claim

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

>![IMPORTANT]
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

> ![NOTE]
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