# Cluster Ugrade Process (by policies)

![tempFileForShare_20241127-144946.png](https://github.com/user-attachments/assets/6d1d3f30-12e7-42df-88cf-add96596ad7a)

## Mirror Images

### Download Images
```
## Operators Images
$ mkdir redhat
$ cat >redhat/redhat.yaml <<EOF
kind: ImageSetConfiguration
apiVersion: mirror.openshift.io/v2alpha1
mirror:
  operators:
  - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.14
    packages:
    - name: advanced-cluster-management
      channels:
      - name: release-2.11
      - name: release-2.10
      - name: release-2.9
        minVersion: 2.9.3
    - name: multicluster-engine
      channels:
      - name: stable-2.6
      - name: stable-2.5
      - name: stable-2.4
        minVersion: 2.4.4
    - name: local-storage-operator
      channels:
      - name: stable
        minVersion: 4.14.0-202409240108
    - name: lvms-operator
      channels:
      - name: stable-4.14
        minVersion: 4.14.6
    - name: servicemeshoperator
      channels:
      - name: stable
      - name: "1.0"
        minVersion: 2.6.1
    - name: kiali-ossm
      channels:
      - name: candidate
      - name: stable
        minVersion: 1.89.1
    - name: jaeger-product
      channels:
      - name: stable
        minVersion: 1.34.1-5
    - name: tempo-product
      channels:
      - name: stable
        minVersion: 0.10.0-8
    - name: netobserv-operator
      channels:
      - name: stable
        minVersion: 1.3.0
    - name: openshift-gitops-operator
      channels:
      - name: latest
      - name: gitops-1.13
        minVersion: 1.13.1
    - name: cincinnati-operator
      channels:
      - name: v1
        minVersion: 5.0.2
    - name: cluster-logging
      channels:
      - name: stable-6.0
      - name: stable-5.9
      - name: stable-5.8
        minVersion: 5.8.14
    - name: kubernetes-nmstate-operator
      channels:
      - name: stable
        minVersion: 4.14.0-202409250809
    - name: node-healthcheck-operator
      channels:
      - name: stable
      - name: 4.16-eus
        minVersion: 0.8.1
    - name: self-node-remediation
      channels:
      - name: stable
      - name: 4.16-eus
        minVersion: 0.8.0
    - name: node-maintenance-operator
      channels:
      - name: stable
      - name: 4.14-eus
        minVersion: 5.2.1
    - name: openshift-custom-metrics-autoscaler-operator
      channels:
      - name: stable
        minVersion: 2.11.2-322
    - name: opentelemetry-product
      channels:
      - name: stable
        minVersion: 0.89.0-3
    - name: web-terminal
      channels:
      - name: fast
        minVersion: 1.6.0
    - name: devworkspace-operator
      channels:
      - name: fast
        minVersion: 0.20.0
    - name: vertical-pod-autoscaler
      channels:
      - name: stable
        minVersion: 4.14.0-202403221232
    - name: metallb-operator
      channels:
      - name: stable
        minVersion: 4.14.0-202406180839
  - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.15
    packages:
    - name: advanced-cluster-management
    - name: multicluster-engine
    - name: local-storage-operator
    - name: lvms-operator
    - name: servicemeshoperator
    - name: kiali-ossm
    - name: jaeger-product
    - name: tempo-product
    - name: netobserv-operator
    - name: openshift-gitops-operator
    - name: cincinnati-operator
    - name: cluster-logging
    - name: kubernetes-nmstate-operator
    - name: node-healthcheck-operator
    - name: self-node-remediation
    - name: node-maintenance-operator
    - name: openshift-custom-metrics-autoscaler-operator
    - name: opentelemetry-product
    - name: web-terminal
    - name: devworkspace-operator
    - name: vertical-pod-autoscaler
    - name: metallb-operator
  - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.16
    packages:
    - name: advanced-cluster-management
    - name: multicluster-engine
    - name: local-storage-operator
    - name: lvms-operator
    - name: servicemeshoperator
    - name: kiali-ossm
    - name: jaeger-product
    - name: tempo-product
    - name: netobserv-operator
    - name: openshift-gitops-operator
    - name: cincinnati-operator
    - name: cluster-logging
    - name: kubernetes-nmstate-operator
    - name: node-healthcheck-operator
    - name: self-node-remediation
    - name: node-maintenance-operator
    - name: openshift-custom-metrics-autoscaler-operator
    - name: opentelemetry-product
    - name: web-terminal
    - name: devworkspace-operator
    - name: vertical-pod-autoscaler
    - name: metallb-operator
  - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.17
    packages:
    - name: advanced-cluster-management
    - name: multicluster-engine
    - name: local-storage-operator
    - name: lvms-operator
    - name: servicemeshoperator
    - name: kiali-ossm
    - name: jaeger-product
    - name: tempo-product
    - name: netobserv-operator
    - name: openshift-gitops-operator
    - name: cincinnati-operator
    - name: cluster-logging
    - name: kubernetes-nmstate-operator
    - name: node-healthcheck-operator
    - name: self-node-remediation
    - name: node-maintenance-operator
    - name: openshift-custom-metrics-autoscaler-operator
    - name: opentelemetry-product
    - name: web-terminal
    - name: devworkspace-operator
    - name: vertical-pod-autoscaler
    - name: metallb-operator
  - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.18
    packages:
    - name: advanced-cluster-management
    - name: multicluster-engine
    - name: local-storage-operator
    - name: lvms-operator
    - name: servicemeshoperator
    - name: kiali-ossm
    - name: jaeger-product
    - name: tempo-product
    - name: netobserv-operator
    - name: openshift-gitops-operator
    - name: cincinnati-operator
    - name: cluster-logging
    - name: kubernetes-nmstate-operator
    - name: node-healthcheck-operator
    - name: self-node-remediation
    - name: node-maintenance-operator
    - name: openshift-custom-metrics-autoscaler-operator
    - name: opentelemetry-product
    - name: web-terminal
    - name: devworkspace-operator
    - name: vertical-pod-autoscaler
    - name: metallb-operator
EOF

$ cat >1.sh <<\EOF
#!/usr/bin/bash
RPN=$(basename $(realpath $1))
[ $? -ne 0 ] && echo "Example: 1.sh <dir>" && exit 1
echo $$ >$1/1.pid
unset ok; while [ "$ok" != "true" ]; do
oc-mirror --v2 --log-level debug --retry-times 999 --image-timeout 1h -c $1/$RPN.yaml file://$1/file >$1/$RPN.out 2>&1
if [ ! -s $1/file/mirror_000001.tar ] || ! grep " mirror time " $1/$RPN.out; then mv $1/$RPN.out $1/$RPN.out.$(date +%Y%m%d_%H%M)
else ok=true; break; fi; done
rm -f $1/$RPN.out.$(date +%Y)* $1/1.pid
EOF

$ nohup sh 1.sh redhat >redhat/1.out 2>&1 &

... Release images skip ...

```

***

... Bring in ...

***

### Upload Images
```
## Operators images
$ cat >2.sh <<\EOF
#!/usr/bin/bash
RPN=$(basename $(realpath $1))
[ $? -ne 0 ] && echo "Example: 2.sh <dir>" && exit 1
RPSTR=$2
RPSTR=${RPSTR:=$HOSTNAME:8443/$RPN}
echo $$ >$1/2.pid
while [ ! -f $1/file/mirror_000001.tar ] || [ -f $1/1.pid ] ; do echo -n \.; sleep 10; done
echo
rm -rf file ~/.oc-mirror; cp -R $1/$1.yaml $1/file .; rm -f file/working-dir/logs/mirroring_errors_*.txt
unset ok; while [ "$ok" != "true" ]; do
oc-mirror --v2 --log-level debug --retry-times 999 --image-timeout 1h -c $1.yaml --from file://file docker://$RPSTR >$1/$RPN-2.out 2>&1
if egrep -v 'Failed to copy|manifest unknown|skipping operator bundle' $1/$RPN-2.out | grep ERROR || ! grep " mirror time " $1/$RPN-2.out; then mv $1/$RPN-2.out $1/$RPN-2.out.$(date +%Y%m%d_%H%M)
else ok=true; break; fi; done
rm -f $1/$RPN-2.out.$(date +%Y)* $1/2.pid
EOF

$ Repository=$HOSTNAME:8443/olm-redhat
$ nohup sh 2.sh redhat $Repository >2.out 2>&1 &

... Release images skip ...


```

### Download the git repo
```
$ git clone https://github.com/belonghim/share
$ cd share/policies/script

```

### Add Release Signatures
```
## Test adding-signuatures script
$ export SIGNATURES=/opt/signatures
$ sh adding-signatures.sh
..

## Apply adding-signuatures
$ sh adding-signatures.sh | oc apply -f -
..

```


<br><br>

## Release Upgrade

### Check ManagedClusterAddOns are all "Available"
```
## Check ManagedClusterAddOns are all "Available"
$ CLUSTER=test
$ oc -n $CLUSTER wait mca --all --for=condition=Available

```

### Check policies.osus label
```
## Check policies.osus label is "ocp4"
$ oc label mcl $CLUSTER policies.osus=ocp4

```

### Check policies.cv states are all "Compliant"
```
## Check cv-check state is "Compliant"
$ oc -n $CLUSTER get policy -l policies.cv
NAME                               REMEDIATION ACTION   COMPLIANCE STATE   AGE
policies.check-cv                  inform               Compliant          3h14m
policies.check-upgradeable         inform               Compliant          3h14m
policies.proxy-sync-managed        enforce              Compliant          3h14m
policies.upgrade-admin-acks        enforce              Compliant          3h14m
policies.upgrade-release-channel   enforce              Compliant          3h14m
policies.upgrade-signatures        enforce              Compliant          3h14m
policies.upgrade-sub-manual        enforce              Compliant          75m
policies.upgrade-upstream          enforce              Compliant          3h14m

```

### Change release channel
```
## Change managecluster's release-channel label
$ CHANNEL=stable-4.18
$ oc label mcl $CLUSTER policies.release-channel=${CHANNEL} --overwrite

```

### Wait channel update
```
## Wait until channel is updated
$ oc -n $CLUSTER wait --timeout=10m --for=jsonpath='{.status.distributionInfo.ocp.channel}'=${CHANNEL} managedclusterinfo $CLUSTER
managedclusterinfo.internal.open-cluster-management.io/test condition met

```

### Wait policies.cv states are all "Compliant"
```
## Wait until policies.cv states are all "Compliant"
$ oc -n $CLUSTER wait --timeout=20m --for=jsonpath='{.status.compliant}'=Compliant policy -l policies.cv
policy.policy.open-cluster-management.io/policies.check-cv condition met
policy.policy.open-cluster-management.io/policies.check-upgradeable condition met
policy.policy.open-cluster-management.io/policies.proxy-sync-managed condition met
policy.policy.open-cluster-management.io/policies.upgrade-admin-acks condition met
policy.policy.open-cluster-management.io/policies.upgrade-release-channel condition met
policy.policy.open-cluster-management.io/policies.upgrade-signatures condition met
policy.policy.open-cluster-management.io/policies.upgrade-sub-manual condition met
policy.policy.open-cluster-management.io/policies.upgrade-upstream condition met

```

### Delete release channel (for signature varification)
```
## Delete managecluster's release-channel label
$ oc label mcl $CLUSTER policies.release-channel-

```

### Execute version upgrade curator
```
## Check available release versions
$ oc -n $CLUSTER get -ojsonpath='{.status.distributionInfo.ocp.availableUpdates}' managedclusterinfo $CLUSTER
...

## set $VERSION variable
$ export VERSION=4.18.1

$ oc -n $CLUSTER wait --timeout=20m --for=jsonpath='{.status.distributionInfo.ocp.availableUpdates[?(@=="'$VERSION'")]}' managedclusterinfo $CLUSTER
managedclusterinfo.internal.open-cluster-management.io/test condition met

## Check check-upgradeable state is "Compliant"
$ oc -n $CLUSTER get policy policies.check-upgradeable
NAME                         REMEDIATION ACTION   COMPLIANCE STATE   AGE
policies.check-upgradeable   inform               Compliant          13h

## Recreate curator-upgrade
$ oc replace --force -f - <<EOF
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: ClusterCurator
metadata:
  name: $CLUSTER
  namespace: $CLUSTER
spec:
  desiredCuration: upgrade
  upgrade:
    desiredUpdate: $VERSION
EOF

```

### Wait version upgrade
```
## Wait until curator-upgrade is updated
$ oc -n $CLUSTER wait --timeout=3h --for=condition=clustercurator-job=true clustercurator $CLUSTER
clustercurator.cluster.open-cluster-management.io/test condition met

## Check clustercurator state is "Job_failed"
$ oc -n $CLUSTER get clustercurator $CLUSTER -ojsonpath='{.status.conditions[?(@.type=="clustercurator-job")].reason}' | grep Job_failed

## If the clustercurator state is "Job_failed", recreate curator-upgrade (Repeat "Wait until curator-upgrade is updated")
$ [ $? -eq 0 ] && sh upgrade.sh | oc replace --force -f -

## Wait until upgrade version is updated
$ oc -n $CLUSTER wait --timeout=1h --for=jsonpath='{.status.distributionInfo.ocp.version}'=${VERSION} managedclusterinfo $CLUSTER

```

### Delete release channel (reconfirm)
```
## Delete managecluster's release-channel label
$ oc label mcl $CLUSTER policies.release-channel-

```

### Wait policies.cv states are all "Compliant"
```
## Wait until policies.cv states are all "Compliant"
$ oc -n $CLUSTER wait --timeout=1h --for=jsonpath='{.status.compliant}'=Compliant policy -l policies.cv
policy.policy.open-cluster-management.io/policies.check-cv condition met
policy.policy.open-cluster-management.io/policies.check-upgradeable condition met
policy.policy.open-cluster-management.io/policies.proxy-sync-managed condition met
policy.policy.open-cluster-management.io/policies.upgrade-admin-acks condition met
policy.policy.open-cluster-management.io/policies.upgrade-release-channel condition met
policy.policy.open-cluster-management.io/policies.upgrade-signatures condition met
policy.policy.open-cluster-management.io/policies.upgrade-sub-manual condition met
policy.policy.open-cluster-management.io/policies.upgrade-upstream condition met

```


<br><br>

## Operators Upgrade

### Check ManagedClusterAddOns are all "Available"
```
## Check ManagedClusterAddOns are all "Available"
$ CLUSTER=test
$ oc -n $CLUSTER wait mca --all --for=condition=Available

```

### Check csv-check
```
## Check policies.csv's state
$ oc -n $CLUSTER get policy -l policies.csv
NAME                          REMEDIATION ACTION   COMPLIANCE STATE   AGE
policies.check-csv            inform               Compliant          15h
policies.check-cv             inform               Compliant          15h
policies.install-operators    enforce              Compliant          15h
policies.upgrade-sub-manual   enforce              Compliant          15h
```

### Change installPlanApproval to automatic
```
## Change managecluster's sub-approval label to automatic
$ oc label --overwrite managedcluster $CLUSTER policies.sub-approval=automatic
managedcluster.cluster.open-cluster-management.io/test labeled

## Check upgrade-sub-automatic state is "Compliant"
$ oc -n $CLUSTER get policy policies.upgrade-sub-automatic
NAME                                  REMEDIATION ACTION   COMPLIANCE STATE   AGE
policies.upgrade-sub-automatic        enforce              Compliant          3m13s

```

### Wait ClusterServiceVersion compliant
```
## Wait for 5 minuates
$ sleep 300

## Check target cluster's policies state
$ oc -n $CLUSTER get policy
..

## Wait until policies.csv states are all "Compliant"
$ oc -n $CLUSTER wait --timeout=1h --for=jsonpath='{.status.compliant}'=Compliant policy -l policies.csv
policy.policy.open-cluster-management.io/policies.check-csv condition met
policy.policy.open-cluster-management.io/policies.check-cv condition met
policy.policy.open-cluster-management.io/policies.install-operators condition met
policy.policy.open-cluster-management.io/policies.upgrade-cs-redhat-operator condition met
policy.policy.open-cluster-management.io/policies.upgrade-marketplace-job condition met
policy.policy.open-cluster-management.io/policies.upgrade-sub-automatic condition met

```

### Change installPlanApproval to manual
```
## Change managecluster's sub-approval label to manual
$ oc label --overwrite managedcluster $CLUSTER policies.sub-approval=manual
managedcluster.cluster.open-cluster-management.io/test labeled

## Check upgrade-sub-manual state is "Compliant"
$ oc -n $CLUSTER get policy policies.upgrade-sub-manual
NAME                               REMEDIATION ACTION   COMPLIANCE STATE   AGE
policies.upgrade-sub-manual        enforce              Compliant          22s

```



