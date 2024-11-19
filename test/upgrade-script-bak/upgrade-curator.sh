CLUSTER=$1
CHANNEL=stable-4.14
VERSION=4.14.38

cat <<EOF
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: ClusterCurator
metadata:
  name: $CLUSTER
  namespace: $CLUSTER
  annotations:
    cluster.open-cluster-management.io/upgrade-clusterversion-backoff-limit: "10"
spec:
  desiredCuration: upgrade
  upgrade:
    channel: $CHANNEL
    desiredUpdate: $VERSION
    prehook:
    - extra_vars: {}
      name: Pause machinepool
      type: Job
EOF

