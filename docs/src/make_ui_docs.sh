mkdir -p tmp
echo "
- [Installing The Operators](rhoai_installing_operators.md)
    - [Installing The OpenShift Pipeline Operator](rhoai_openshift_pipeline_operator_ui.md)
    - [Installing The OpenShift AI Operator](rhoai_openshiftai_operator_ui.md)
    - [Installing The NVIDIA GPU Operator](blank.md)
        - [Node Feature Discovery](nvidia_node_discovery_operator_ui.md)
        - [NVIDIA Operator](nvidia_operator_ui.md)
        - [NVIDIA Cluster Monitoring](nvidia_cluster_monitoring_cli.md)
    - [NVIDIA - Configuring Time Slicing](nvidia_time_slicing_ui.md)
- [Workbench Basics](rhoai_workbench_generic.md)
    - [Setting Up A Workbench](rhoai_workbench_ui.md)
    - [Rolebindings](rhoai_rbac_generic.md)
        - [Workbench RBAC](rhoai_rbac_ui.md)
    - [Default PVC For Notebookes](rhoai_pvc_notebook_generic.md)
        - [Workbench PVC](rhoai_pvc_notebooks_ui.md)
    - [Dealing With Idle Notebooks](rhoai_idle_notebooks_generic.md)
        - [Workbench Idle Notebooks](rhoai_idle_notebooks_ui.md)
    - [Creating A Pipeline Server](rhoai_pipeline_server_generic.md)
        - [Pipeline Servers](rhoai_pipeline_server_ui.md)
" > tmp/summary.md

cd tmp
for file in rhoai_idle_notebooks_ui.md  rhoai_openshiftai_operator_ui.md  rhoai_openshift_pipeline_operator_ui.md  rhoai_pipeline_server_ui.md  rhoai_pvc_notebooks_ui.md  rhoai_rbac_ui.md  rhoai_workbench_ui.md nvidia_node_discovery_operator_ui.md nvidia_operator_ui.md nvidia_time_slicing_ui.md; do
  ln -s ../UI/"${file}"
done

for file in nvidia_cluster_monitoring_cli.md; do
  ln -s ../CLI/"${file}"
done

touch blank.md

for file in rhoai_idle_notebooks_generic.md  rhoai_pipeline_server_generic.md  rhoai_pvc_notebook_generic.md  rhoai_rbac_generic.md  rhoai_workbench_generic.md rhoai_installing_operators.md; do
  ln -s ../generic/"${file}"
done

cd ..

./stitchmd -C tmp -o ../rendered/OpenShift_AI_User_Interface.md tmp/summary.md

rm -rf tmp

