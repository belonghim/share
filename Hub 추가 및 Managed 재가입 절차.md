<!-- + 도와주세요 -->

# Hub 추가 및 Managed 재가입 절차

<br><br>
## DNS 구성

### add DNS records

```
... skip ...
```

<br><br>
## Bastion(또는 Installer pod) 준비 절차

### 사전 설치된 Packages 확인

```
... skip ...
```

### 사전 다운로드된 tools 확인

```
... skip ...
```

### DNS 확인

```
... skip ...
```

### ping 테스트

```
... skip ...
```

### sshKey 확인

```
... skip ...
```

### additionalTrustBundle 확인

```
... skip ...
```

### image info 확인

```
... skip ...
```

### install config 준비

```
... skip ...
```

### agent config 구성

```
... skip ...
```

<br><br>
## Installer 실행

### agent cluster-manifests 생성

```
... skip ...
```

### cluster-manifests 파일들 추가

```
... skip ...
```

### agent image 생성
```
... skip ...
```

<br><br>
## VM 노드 생성

### vm.create

```
... skip ...
```

### disk.enableUUID 설정 및 시작

```
... skip ...
```

<br><br>
## 설치 후 구성 명령

###
```
$ openshift-install agent wait-for bootstrap-complete --dir ${Install_Dir} --log-level=debug
```

### Set node labels
```
## set DOMAIN variable
$ DOMAIN=new-hub.woorifg.lab

## Set acm node labels
$ oc label node infra-0.$DOMAIN node-role.kubernetes.io/acm= 
$ oc label node infra-1.$DOMAIN node-role.kubernetes.io/acm= 
$ oc label node infra-2.$DOMAIN node-role.kubernetes.io/acm= 

## Set quay node labels
$ oc label node infra-0.$DOMAIN node-role.kubernetes.io/infra= 
$ oc label node infra-1.$DOMAIN node-role.kubernetes.io/infra= 
$ oc label node infra-2.$DOMAIN node-role.kubernetes.io/infra= 

```

### Delete acm MCP (for extra hub)
```
## Delete mcp/acm 
$ oc delete mcp/acm

```

### Deploy ACM operator
```
## create Namespace, OperatorGroup, Subscription for  operator
$ oc create -f -<<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: open-cluster-management
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: open-cluster-management
  namespace: open-cluster-management
spec:
  targetNamespaces:
  - open-cluster-management
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: advanced-cluster-management
  namespace: open-cluster-management
spec:
  installPlanApproval: Automatic
  name: advanced-cluster-management
  source: cs-redhat-operator-index
  sourceNamespace: openshift-marketplace
  config:
    nodeSelector:
      node-role.kubernetes.io/acm: ""
    tolerations:
    - effect: NoSchedule
      operator: Exists
      key: node-role.kubernetes.io/infra
EOF

## Wait until the CSV is succeeded
$ oc -n open-cluster-management wait csv -l \!olm.copiedFrom --for=jsonpath={.status.phase}=Succeeded
```

### Create MultiClusterHub
```
## Create the multiclusterhub
$ oc create -f - <<EOF
apiVersion: operator.open-cluster-management.io/v1
kind: MultiClusterHub
metadata:
  namespace: open-cluster-management
  name: multiclusterhub
spec:
  disableUpdateClusterImageSets: true
  nodeSelector:
    node-role.kubernetes.io/acm: ""
  tolerations:
  - effect: NoSchedule
    operator: Exists
    key: node-role.kubernetes.io/infra
EOF

## Wait until the MCH is running
$ oc -n open-cluster-management wait --timeout=10m mch/multiclusterhub --for=jsonpath={.status.phase}=Running

## Wait until the MCE is available
$ oc wait --timeout=10m mce/multiclusterengine --for=jsonpath={.status.phase}=Available

## Wait until the MCH is running
$ oc -n open-cluster-management wait --timeout=10m mch/multiclusterhub --for=jsonpath={.status.phase}=Running

```

### Update ClusterManagementAddon 
```
## Create AddOnDeploymentConfig
$ oc create -f - <<EOF
apiVersion: addon.open-cluster-management.io/v1alpha1
kind: AddOnDeploymentConfig
metadata:
  name: managed
  namespace: open-cluster-management-hub
spec:
  nodePlacement:
    tolerations:
    - key: node-role.kubernetes.io/infra
      operator: Exists
      effect: NoSchedule
---
apiVersion: addon.open-cluster-management.io/v1alpha1
kind: AddOnDeploymentConfig
metadata:
  name: hub
  namespace: open-cluster-management-hub
spec:
  nodePlacement:
    tolerations:
    - key: node-role.kubernetes.io/infra
      operator: Exists
      effect: NoSchedule
    nodeSelector:
      node-role.kubernetes.io/acm: ""
EOF

```

### Create Namespace/policies
```
## Create Namespace, ManagedClusterSetBinding
$ oc create -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
    name: policies
---
apiVersion: cluster.open-cluster-management.io/v1beta2
kind: ManagedClusterSetBinding
metadata:
    name: default
    namespace: policies
spec:
    clusterSet: default
EOF
```

### Apply the policies
```
## Apply the OPP policies
$ oc apply -f bon.yaml


#### Additional policies

## Test osus policy
$ Registry=gps03.redhat.lab:5000
$ sh script/osus.sh ${Registry}

## Apply osus policy
$ sh script/osus.sh ${Registry} | oc create -f -

```

### Apply osus
```
$ oc label mcl local-cluster policies.osus=ocp4
```

### Apply cluster-log-forwarder
```
$ oc -n policies create cm config-operators --from-literal logTopic=test --from-literal logBrokers='["tcp://192.168.10.3:7777","tcp://192.168.10.4:7777","tcp://192.168.10.5:7777"]'
```

### (Optional) Apply dev environment
```
$ oc label mcl local-cluster policies.extra=dev
```

### Check the policies & operators
```
## Check the policies and operators
$ oc get policy,sub,csv,ip -A -l \!olm.copiedFrom

```


<br><br>
## Reimporting to New Hub Cluster

### Delete Managed Cluster from old Hub Cluster
```
## Delete Managed Cluster from old Hub Cluster
$ CLUSTER=paas
$ export KUBECONFIG=/opt/$CLUSTER/auth/kubeconfig
$ oc delete --cascade=foreground managedcluster mngda
$ oc delete ns mngda

```

### Preparing for cluster import
```
## create Namespace
$ ManagedCluster=mngda
$ oc create namespace ${ManagedCluster}

## create ManagedCluster
$ oc create -f - <<EOF
apiVersion: cluster.open-cluster-management.io/v1
kind: ManagedCluster
metadata:
  name: ${ManagedCluster}
  annotations:
    open-cluster-management/tolerations: '[{"key":"node-role.kubernetes.io/infra","operator":"Exists","effect":"NoSchedule"}]'
  labels:
    cloud: auto-detect
    vendor: OpenShift
    policies.osus: ocp4
spec:
  hubAcceptsClient: true
EOF
```

### Importing managed cluster by using the auto import secret
```
## create auto import secret
$ ManagedKubeconfig="/opt/mngda/auth/kubeconfig"
$ oc create -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: auto-import-secret
  namespace: ${ManagedCluster}
  annotations:
    managedcluster-import-controller.open-cluster-management.io/keeping-auto-import-secret: ""
stringData:
  autoImportRetry: "720"
  kubeconfig: |-
$(sed 's/^/    /g' ${ManagedKubeconfig})
type: Opaque
EOF

## create klusterlet addon config
$ oc create -f - <<EOF
apiVersion: agent.open-cluster-management.io/v1
kind: KlusterletAddonConfig
metadata:
  name: ${ManagedCluster}
  namespace: ${ManagedCluster}
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
EOF

### (Optional) Apply dev environment
```
$ oc label mcl ${ManagedCluster} policies.extra=dev
```

## Validate the JOINED and AVAILABLE status of the managed cluster
$ oc get managedcluster ${ManagedKubeconfig}

```


### Delete auto-import secret
```
## Wait until the managedluster joined
$ oc wait mcl ${ManagedCluster} --for=condition=ManagedClusterImportSucceeded && oc wait mcl ${ManagedCluster} --for=condition=ManagedClusterConditionAvailable && oc wait mcl ${ManagedCluster} --for=condition=ManagedClusterJoined

## Delete auto-import-secret
$ oc -n ${ManagedCluster} delete secret auto-import-secret

```

