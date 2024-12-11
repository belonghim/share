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
    vendor: OpenShift
    policies.osus: ocp4
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
  #token: sha256~fywkF0ePyj7wP_Hi7RLrfGYDL-0BQ-2Accc7GR6orKI
  #server: https://api.sno-a.wooribank.lab:6443
  autoImportRetry: "720"
  kubeconfig: |-
$(sed 's/^/    /g' $KUBECON)
type: Opaque
EOF
