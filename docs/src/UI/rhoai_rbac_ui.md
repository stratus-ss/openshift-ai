
### Using OpenShift AI's Dashboard

OpenShift AI's Dashboard is an object inside of OpenShift. By default the Dashboard will have the option to "Log in with OpenShift"

![login](../images/ai_login_with_openshift.png)

This means if you have an authentication provider configured by an OpenShift Administrator, those users and groups will be available within the OpenShift AI Dashboard. There is a distinction between users who are allowed to login to the OpenShift AI Dashboard and users who have access to various Data Science Projects.

### UI - Controlling Access To The Dashboard Itself

There are two methods for manipulating group access. First, the OpenShift AI Dashboard (assuming the user you are logged in as has the appropriate permissions) allows administrators to select via a drop down groups:

![user_mgmt1.png](../images/ai_user_mgmt1.png).

> [!IMPORTANT]
> By default the `system:authenticated` group is selected. This allows anyone who can log into OpenShift to have access to the OpenShift AI Dashboard. This may not be what you want.

When you make a change to the user or group, the Dashboard Config object is edited for you. The operator, which resides in the project `redhat-ods-operator` will reconcile the changes made to this object after a short period of time by merging the changes with the active configuration of the containers.

### UI - Controlling Data Science Project Access

You may wish to grant users or groups to various roles inside of a Data Science Project as well. In order to do this, select Data Science Projects --> Your Project  --> Permissions:

![proj_mgmt](../images/ai_proj_mgmt1.png)

From here you can select the various roles you might have created in your OpenShift Cluster. By default the Edit and Admin options are available.


