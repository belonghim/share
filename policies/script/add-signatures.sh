if [ "$SIGNATURES" = "" ];then SIGNATURES=$1;fi
if [ "$SIGNATURES" = "" ];then echo "Example: add-signatures.sh <signatures_dir>";exit 1;fi

oc create -f $SIGNATURES --dry-run=client -oyaml | sed 's/openshift-config-managed/policies/g'
