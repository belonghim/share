CLUSTER=$1
MRR=release-41611-41703
CHANNEL=stable-4.17
VERSION=4.17.3

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

