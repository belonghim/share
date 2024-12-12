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
$ while ! oc -n open-cluster-management wait csv -l \!olm.copiedFrom --for=jsonpath={.status.phase}=Succeeded;do echo sleep 10;done
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

```

### Update ClusterManagementAddon 
```
## Create AddOnDeploymentConfig
$ oc create -f - <<EOF
apiVersion: addon.open-cluster-management.io/v1alpha1
kind: AddOnDeploymentConfig
metadata:
  name: global
  namespace: open-cluster-management-hub
spec:
  nodePlacement:
    tolerations:
      - key: node-role.kubernetes.io/infra
        operator: Exists
        effect: NoSchedule
EOF

## Update ClusterManagementAddon
$ for f in $(oc get clustermanagementaddon -oname);do
oc patch $f --type='json' -p='[{"op":"add", "path":"/spec/supportedConfigs", "value":[{"group":"addon.open-cluster-management.io","resource":"addondeploymentconfigs", "defaultConfig":{"name":"global","namespace":"open-cluster-management-hub"}}]}]'
done

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

## Install PolicyGenerator
```
## download & install PolicyGenerator
$ wget https://github.com/open-cluster-management-io/policy-generator-plugin/releases/download/v1.16.0/linux-amd64-PolicyGenerator

$ chmod 755 linux-amd64-PolicyGenerator 
$ mkdir -p ${HOME}/.config/kustomize/plugin/policy.open-cluster-management.io/v1/policygenerator
$ mv linux-amd64-PolicyGenerator ${HOME}/.config/kustomize/plugin/policy.open-cluster-management.io/v1/policygenerator/PolicyGenerator
```

## Apply the policies
```
## Download the git repo
$ git clone https://github.com/belonghim/share

## Generate policies
$ cd share/test/mzc
$ oc kustomize --enable-alpha-plugins --output ../mzc.yaml

## Apply the OPP policies
$ oc apply -f ../mzc.yaml


#### Additional policies
$ cd ../script

## Test osus policy
$ sh hub-osus.sh

## Apply osus policy
$ sh hub-osus.sh | oc create -f -

```

## Check the policies & operators
```
## Check the policies and operators
$ oc get policy,sub,csv,ip -A -l \!olm.copiedFrom
```

