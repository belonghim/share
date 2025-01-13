SIGNATURES=/data/registry/release/release-signatures/

oc create -f $SIGNATURES --dry-run=client -oyaml | sed 's/openshift-config-managed/policies/g'
