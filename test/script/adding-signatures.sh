SIGNATURES=/root/mirror/result/release-signatures/

oc create -f $SIGNATURES --dry-run=client -oyaml | sed 's/openshift-config-managed/policies/g'
