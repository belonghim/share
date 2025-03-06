if [ "$CLUSTER" = "" ];then CLUSTER=$1;fi
if [ "$KUBECON" = "" ];then KUBECON=$2;fi
if [ "$CLUSTER" = "" -o "$KUBECON" = "" ];then echo "Example: import-cluster.sh <cluster> <kubeconfig>";exit 1;fi

cat <<EOF
---
apiVersion: v1
kind: Namespace
metadata:
  name: $CLUSTER
---
apiVersion: v1
kind: Secret
metadata:
  name: auto-import-secret
  namespace: $CLUSTER
  annotations:
    managedcluster-import-controller.open-cluster-management.io/keeping-auto-import-secret: ""
stringData:
  #token: sha256~fywkF0ePyj7wP_Hi7RLrfGYDL-0BQ-2Accc7GR6orKI
  #server: https://api.sno-a.woorifg.lab:6443
  autoImportRetry: "21600"
  kubeconfig: |-
$(sed 's/^/    /g' $KUBECON)
type: Opaque
---
apiVersion: agent.open-cluster-management.io/v1
kind: KlusterletAddonConfig
metadata:
  name: $CLUSTER
  namespace: $CLUSTER
spec:
  applicationManager:
    enabled: false
  certPolicyController:
    enabled: true
  iamPolicyController:
    enabled: false
  policyController:
    enabled: true
  searchCollector:
    enabled: true
---
apiVersion: cluster.open-cluster-management.io/v1
kind: ManagedCluster
metadata:
  name: $CLUSTER
  annotations:
    open-cluster-management/tolerations: '[{"key":"node-role.kubernetes.io/infra","operator":"Exists","effect":"NoSchedule"}]'
  labels:
    cloud: auto-detect
    vendor: OpenShift
    policies.osus: ocp4
spec:
  hubAcceptsClient: true
  leaseDurationSeconds: 120
EOF
