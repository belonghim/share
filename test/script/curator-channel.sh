CLUSTER=$1
CHANNEL=stable-4.17

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
EOF

