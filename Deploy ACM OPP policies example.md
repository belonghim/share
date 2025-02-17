# Deploy ACM OPP policies example


## MultiClusterHub Preparation

### Set node labels
```
## set DOMAIN variable
$ DOMAIN=hub.woorifg.lab

## Set acm node labels
$ oc label node acm-0.$DOMAIN node-role.kubernetes.io/acm= 
$ oc label node acm-1.$DOMAIN node-role.kubernetes.io/acm= 
$ oc label node acm-2.$DOMAIN node-role.kubernetes.io/acm= 

## Set infra node labels
$ oc label node infra-0.$DOMAIN node-role.kubernetes.io/infra= 
$ oc label node infra-1.$DOMAIN node-role.kubernetes.io/infra= 
$ oc label node infra-2.$DOMAIN node-role.kubernetes.io/infra= 

```


## Deploy ACM operator
```
## create Namespace, OperatorGroup, Subscription for ACM operator
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
$ while ! oc -n open-cluster-management wait csv -l \!olm.copiedFrom --for=jsonpath={.status.phase}=Succeeded;do sleep 10;done
```

## Create MultiClusterHub
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


## Make Policies 

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

### Install PolicyGenerator
```
## download & install PolicyGenerator
$ wget https://github.com/open-cluster-management-io/policy-generator-plugin/releases/download/v1.16.0/linux-amd64-PolicyGenerator

$ chmod 755 linux-amd64-PolicyGenerator 
$ mkdir -p ${HOME}/.config/kustomize/plugin/policy.open-cluster-management.io/v1/policygenerator
$ mv linux-amd64-PolicyGenerator ${HOME}/.config/kustomize/plugin/policy.open-cluster-management.io/v1/policygenerator/PolicyGenerator
```

### Apply the policies
```
## Download the git repo
$ git clone https://github.com/belonghim/share

## Generate policies
$ cd share/policies/bon
$ oc kustomize --enable-alpha-plugins --output ../bon.yaml

## Apply the OPP policies
$ oc apply -f ../bon.yaml


#### Additional policies
$ cd ../script

## Test osus policy
$ export REGISTRY=gps03.redhat.lab:5000
$ sh osus.sh

## Apply osus policy
$ sh osus.sh | oc create -f -

```

### Apply osus
```
$ oc label mcl local-cluster policies.osus=ocp4
```

### Apply cluster-log-forwarder
```
$ oc -n policies create cm config-operators --from-literal logTopic=test --from-literal logBrokers='["tcp://192.168.10.3:7777","tcp://192.168.10.4:7777","tcp://192.168.10.5:7777"]'
```

### Check the policies & operators
```
## Check the policies and operators
$ oc get policy,sub,csv,ip -A -l \!olm.copiedFrom
```

