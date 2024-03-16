mkdir -p tmp
echo "
- [Installing The Operators](rhoai_installing_operators.md)
    - [Installing The OpenShift AI Operator](rhoai_openshiftai_operator_cli.md)
    - [Installing The OpenShift Pipeline Operator](rhoai_openshiftai_operator_cli.md)
- [Workbench Basics](rhoai_workbench_generic.md)
    - [Setting Up A Workbench](rhoai_workbench_cli.md)
    - [Rolebindings](rhoai_rbac_generic.md)
        - [Workbench RBAC](rhoai_rbac_cli.md)
    - [Default PVC For Notebookes](rhoai_pvc_notebook_generic.md)
        - [Workbench PVC](rhoai_pvc_notebooks_cli.md)
    - [Dealing With Idle Notebooks](rhoai_idle_notebooks_generic.md)
        - [Workbench Idle Notebooks](rhoai_idle_notebooks_cli.md)
    - [Creating A Pipeline Server](rhoai_pipeline_server_generic.md)
        - [Pipeline Servers](rhoai_pipeline_server_cli.md)
" > tmp/summary.md

cd tmp
for file in rhoai_idle_notebooks_cli.md  rhoai_openshiftai_operator_cli.md  rhoai_openshift_pipeline_operator_cli.md  rhoai_pipeline_server_cli.md  rhoai_pvc_notebooks_cli.md  rhoai_rbac_cli.md  rhoai_workbench_cli.md; do
  ln -s ../CLI/"${file}"
done

for file in rhoai_idle_notebooks_generic.md  rhoai_pipeline_server_generic.md  rhoai_pvc_notebook_generic.md  rhoai_rbac_generic.md  rhoai_workbench_generic.md rhoai_installing_operators.md; do
  ln -s ../generic/"${file}"
done

cd ..

./stitchmd -C tmp -o ../rendered/OpenShift_AI_CLI.md tmp/summary.md

rm -rf tmp

