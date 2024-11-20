CLUSTER=$1
CHANNEL=eus-4.16
VERSION=4.15.35

cat <<EOF
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: ClusterCurator
metadata:
  name: $CLUSTER
  namespace: $CLUSTER
spec:
  desiredCuration: upgrade
  upgrade:
    channel: $CHANNEL
    desiredUpdate: $VERSION
EOF

