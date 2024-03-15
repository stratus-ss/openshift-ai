### UI - Pipeline Server

In The OpenShift AI UI, navigate to `Data Science Projects --> <your project>`. 

![dsp](../images/ai_datascience_project.png)

Once you have selected the desired project, you will see the requisite objects (Workbenches, Cluster Storage, Data Conenctions etc)

![pipeline_server](../images/ai_pipeline_server.png)

Select `Configure Pipeline Server`. You will be greated with the option of inputting your Data Connection details.

![pipeline_server_options](../images/ai_pipeline_server_options.png)

Alternatively, you can click the the key icon and populate the form with any Data Connection available in the project:

![pipeline_prepopulate](../images/ai_pipeline_server_options2.png)

Once this is complete, the UI will not show any pipelines. However, the `Import Pipeline` button will now be available where it was greyed out before:

![pipeline_import](../images/ai_pipeline_import.png)

At this point the cluster will have created 4 deployments in your Data Science Project

```
ds-pipeline-persistenceagent-pipelines-definition
ds-pipeline-pipelines-definition                 
ds-pipeline-scheduledworkflow-pipelines-definition
mariadb-pipelines-definition  
```

OpenShift AI is now ready to handle AI pipelines.

