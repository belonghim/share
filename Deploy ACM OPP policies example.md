
Deploy ACM OPP policies example


MultiClusterHub Preparation
Set node labels
## set CLUSTER variable
$ CLUSTER=compact

## set BASE variable
$ BASE=wooribank.lab

## set DOMAIN variable
$ DOMAIN=$CLUSTER.$BASE

## Set acm node labels
$ oc label node acm-0.$DOMAIN node-role.kubernetes.io/acm= 
$ oc label node acm-1.$DOMAIN node-role.kubernetes.io/acm= 
$ oc label node acm-2.$DOMAIN node-role.kubernetes.io/acm= 

## Set quay node labels
$ oc label node quay-0.$DOMAIN node-role.kubernetes.io/quay= 
$ oc label node quay-1.$DOMAIN node-role.kubernetes.io/quay= 
$ oc label node quay-2.$DOMAIN node-role.kubernetes.io/quay= 

## Set storage node labels
$ oc label node odf-0.$DOMAIN cluster.ocs.openshift.io/openshift-storage=
$ oc label node odf-1.$DOMAIN cluster.ocs.openshift.io/openshift-storage=
$ oc label node odf-2.$DOMAIN cluster.ocs.openshift.io/openshift-storage=

Deploy ACM operator
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
  channel: release-2.9
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


Create MultiClusterHub
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

Make Policies 
Create Namespace/policies
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

Install PolicyGenerator
## download & install PolicyGenerator
$ wget https://github.com/open-cluster-management-io/policy-generator-plugin/releases/download/v1.16.0/linux-amd64-PolicyGenerator

$ chmod 755 linux-amd64-PolicyGenerator 
$ mkdir -p ${HOME}/.config/kustomize/plugin/policy.open-cluster-management.io/v1/policygenerator
$ mv linux-amd64-PolicyGenerator ${HOME}/.config/kustomize/plugin/policy.open-cluster-management.io/v1/policygenerator/PolicyGenerator


Apply the policies
## Download the git repo
$ git clone https://github.com/belonghim/share

## Generate policies
$ cd share/test/sundo
$ oc kustomize --enable-alpha-plugins --output ../sundo.yaml

## Apply the OPP policies
$ oc apply -f ../sundo.yaml


Check the policies & operators
## Check the policies and operators
$ oc get policy,sub,csv,ip -A -l \!olm.copiedFrom


