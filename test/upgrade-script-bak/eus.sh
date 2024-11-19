CLUSTER=$1
CHANNEL=eus-4.16
INTER_V=4.15.35
VERSION=4.16.15

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
    intermediateUpdate: $INTER_V
    desiredUpdate: $VERSION
    posthook:
    - extra_vars: {}
      name: Unpause machinepool
      type: Job
    prehook:
    - extra_vars: {}
      name: Pause machinepool
      type: Job
EOF

