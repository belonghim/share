SIGNATURES=/data01/temp/mirror/ocp414-416/result/release-signatures/
oc create -f $SIGNATURES --dry-run=client -oyaml | sed 's/openshift-config-managed/policies/g'
