if [ "$CLUSTER" = "" ];then CLUSTER=$1;fi
if [ "$VERSION" = "" ];then VERSION=$2;fi
if [ "$CLUSTER" = "" -o "$VERSION" = "" ];then echo "Example: upgrade.sh <cluster> <Version>";exit 1;fi
cat <<EOF
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: ClusterCurator
metadata:
  name: $CLUSTER
  namespace: $CLUSTER
spec:
  desiredCuration: upgrade
  upgrade:
    desiredUpdate: $VERSION
EOF
