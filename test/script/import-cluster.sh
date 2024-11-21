CLUSTER=compact
KUBECON=/opt/compact/auth/kubeconfig

cat <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $CLUSTER
---
apiVersion: cluster.open-cluster-management.io/v1
kind: ManagedCluster
metadata:
  name: $CLUSTER
  labels:
    cloud: auto-detect
    vendor: auto-detect
spec:
  hubAcceptsClient: true
  leaseDurationSeconds: 300
---
apiVersion: agent.open-cluster-management.io/v1
kind: KlusterletAddonConfig
metadata:
  name: $CLUSTER
  namespace: $CLUSTER
spec:
  applicationManager:
    enabled: true
  certPolicyController:
    enabled: true
  iamPolicyController:
    enabled: false
  policyController:
    enabled: true
  searchCollector:
    enabled: false
---
apiVersion: v1
kind: Secret
metadata:
  name: auto-import-secret
  namespace: $CLUSTER
stringData:
  autoImportRetry: "120"
  kubeconfig: |-
$(sed 's/^/    /g' $KUBECON)
type: Opaque
EOF
