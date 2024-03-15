mkdir -p tmp
echo "
- [Installing The OpenShift AI Operator](rhoai_openshiftai_operator_ui.md)
- [Installing The OpenShift Pipeline Operator](rhoai_openshiftai_operator_ui.md)
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
for file in rhoai_idle_notebooks_ui.md  rhoai_openshiftai_operator_ui.md  rhoai_openshift_pipeline_operator_ui.md  rhoai_pipeline_server_ui.md  rhoai_pvc_notebooks_ui.md  rhoai_rbac_ui.md  rhoai_workbench_ui.md; do
  ln -s ../UI/"${file}"
done

for file in rhoai_idle_notebooks_generic.md  rhoai_pipeline_server_generic.md  rhoai_pvc_notebook_generic.md  rhoai_rbac_generic.md  rhoai_workbench_generic.md; do
  ln -s ../generic/"${file}"
done

cd ..

./stitchmd -C tmp -o ../rendered/OpenShift_AI_User_Interface.md tmp/summary.md

rm -rf tmp

