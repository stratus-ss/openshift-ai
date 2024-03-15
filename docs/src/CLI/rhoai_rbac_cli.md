## Dealing With Projects

### Enabling A Specific Project

Specifically, the label `opendatahub.io/dashboard=true` allows the project to be interacted with from the OpenShift AI Dashboard.

The below sample command will label `some-proj` for use with the Dashboard.

```
oc label namespace some-proj opendatahub.io/dashboard=true
```

Optionally, you can also add `modelmesh-enabled='true'` where applicable to further enhance a project.

### Creating Data Science Projects

Because Data Science Projects are simply OpenShift Projects with an extra label or two, the same rules apply. Namely, by default the `self-provisioner` is assigned to the `system:authenticated` group. This means that in the default configuration, anyone who can log in to OpenShift, can create a Data Science Project. In addition, the user that creates the project will automatically become the project administrator. 

### Controlling Data Science Project Access

The process of granting access to a Data Science Project is the same as a regular OpenShift project. In general there are `view`, `edit` and `admin` roles. You would simply issue the following command:

```
oc adm policy add-role-to-group <role> <group name> -n <data science project name>
```

### Prevent Data Science Project Creation

In order to prevent users from creating their own Data Science Project, you will need to patch the clusterrolebinding:
```
oc patch clusterrolebinding.rbac self-provisioners -p '{"subjects": null}'
```
> [!WARNING]
> This will disable all users from creating all projects in the OpenShift cluster where OpenShift AI is running


## Controlling Access To The Dashboard Itself
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

