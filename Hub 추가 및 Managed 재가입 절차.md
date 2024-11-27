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
```

```

<br><br>
## Importing to Hub Cluster

### Preparing for cluster import (in Hub Cluster)
```
## create Namespace
$ ManagedCluster=compact
$ oc create namespace ${ManagedCluster}

## create ManagedCluster
$ oc create -f - <<EOF
apiVersion: cluster.open-cluster-management.io/v1
kind: ManagedCluster
metadata:
  name: ${ManagedCluster}
  labels:
    cloud: auto-detect
    vendor: auto-detect
spec:
  hubAcceptsClient: true
EOF
```

### Importing a cluster by using the auto import secret (in Hub Cluster)
```
## create auto import secret
$ ManagedKubeconfig="/opt/compact/auth/kubeconfig"
$ oc create -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: auto-import-secret
  namespace: ${ManagedCluster}
stringData:
  autoImportRetry: "120"
  kubeconfig: |-
$(sed 's/^/    /g' ${ManagedKubeconfig})
type: Opaque
EOF

## create klusterlet addon config
$ oc create -f - <<EOF
apiVersion: agent.open-cluster-management.io/v1
kind: KlusterletAddonConfig
metadata:
  name: ${ManagedKubeconfig}
  namespace: ${ManagedKubeconfig}
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
EOF

## Validate the JOINED and AVAILABLE status of the managed cluster
$ oc get managedcluster ${ManagedKubeconfig}

```

<br><br>
## Adding AgentBased node
- https://github.com/openshift/enhancements/blob/master/enhancements/oc/day2-add-nodes.md

### DNS 에 node 추가

```
worker2.ocp4.example.com.	IN	A	192.168.1.15
```

### nodes-config.yaml

```
$ mkdir add ;cd add

## create nodes-config.yaml 
$ cat > nodes-config.yaml<<EOF
hosts:
- hostname: worker2.ocp4.example.com
  rootDeviceHints:
    deviceName: /dev/disk/by-path/pci-0000:05:00.0
  interfaces:
  - macAddress: 00:ef:50:30:f5:b0
    name: enp1s0
  networkConfig:
    interfaces:
    - name: enp1s0
      type: ethernet
      state: up
      ipv4:
        enabled: true
        address:
          - ip: 192.168.1.15
            prefix-length: 24
        dhcp: false
      ipv6:
        enabled: false
    dns-resolver:
      config:
        server:
        - 192.168.1.5
    routes:
      config:
      - destination: 0.0.0.0/0
        next-hop-address: 192.168.1.1
        next-hop-interface: enp1s0
        table-id: 254
EOF
```

### node-image create

```
## ocp 4.17 based command
$ oc adm node-image create

## ocp 4.16 based command
## https://github.com/openshift/installer/blob/master/docs/user/agent/add-node/add-nodes.md
$ ./node-joiner.sh
```

### vm.create

```
## On the command line, power off and delete the preexisting virtual machine:
$ /usr/local/bin/govc vm.power -off $VM
$ /usr/local/bin/govc vm.destroy $VM

## Remove the preexisting ISO image from the data store:
$ govc datastore.rm -ds <iso_datastore> node.iso

## Upload the Assisted Installer discovery ISO:
$ govc datastore.upload -ds <iso_datastore> node.iso

## Boot at the worker node:
$ govc vm.create -net.adapter <network_adapter_type> \
                 -disk.controller <disk_controller_type> \
                 -pool=<resource_pool> \
                 -c=4 \
                 -m=8192 \
                 -disk=120GB \
                 -disk-datastore=<datastore_file> \
                 -net.address="<nic_mac_address>" \
                 -iso-datastore=<iso_datastore> \
                 -iso="node.iso" \
                 -folder="<inventory_folder>" \
                 <hostname>.<cluster_name>.example.com

## Ensure the VMs are running:
$  govc ls /<datacenter>/vm/<folder_name>

## After 2 minutes, shut down the VMs:
$ govc vm.power -s=true $VM
```

### disk.enableUUID 설정 및 시작

```
## Set the disk.enableUUID setting to TRUE:
$ govc vm.change -vm $VM -e disk.enableUUID=TRUE

## Restart the VM:
$ govc vm.power -on=true $VM
```

### Joing the node

```
## approval the node csr
$ NODE=worker2.ocp4.example.com
$ for f in $(oc get csr | grep Pending | awk '{print $1}');do echo $f;oc get csr $f -o jsonpath='{.spec.request}'|base64 --decode|openssl req -noout -text|grep $NODE && oc adm certificate approve $f;done

```

<br><br>
## 보안 취약점 조치 예

### kubelet log level

```
$ oc create -f - <<EOF
apiVersion: machineconfiguration.openshift.io/v1
 kind: MachineConfig
 metadata:
   labels:
     machineconfiguration.openshift.io/role: worker
   name: 99-worker-kubelet-loglevel
 spec:
   config:
     ignition:
       version: 3.2.0
     systemd:
       units:
         - name: kubelet.service
           enabled: true
           dropins:
             - name: 30-logging.conf
               contents: |
                 [Service]
                 Environment="KUBELET_LOG_LEVEL=4"
EOF
```
