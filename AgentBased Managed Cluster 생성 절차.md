<!-- + 도와주세요 -->

# AgentBased Managed Cluster 생성 절차

## 절차별 예시 구성도
![image](https://github.com/belonghim/share/blob/main/Screenshot_20241004_151744_Slides.jpg)

<br><br>
## DNS 구성

### named conf DNS records 예시

```
$TTL 1W
@	IN	SOA	ns1.example.com.	root (
			2019070700	; serial
			3H		; refresh (3 hours)
			30M		; retry (30 minutes)
			2W		; expiry (2 weeks)
			1W )		; minimum (1 week)
	IN	NS	ns1.example.com.
	IN	MX 10	smtp.example.com.
;
;
ns1.example.com.		IN	A	192.168.1.5
smtp.example.com.		IN	A	192.168.1.5
;
registry.example.com.		IN	A	192.168.1.200
registry.ocp4.example.com.	IN	A	192.168.1.200
;
api.ocp4.example.com.		IN	A	192.168.1.7
api-int.ocp4.example.com.	IN	A	192.168.1.7
;
*.apps.ocp4.example.com.	IN	A	192.168.1.8
;
master0.ocp4.example.com.	IN	A	192.168.1.10 
master1.ocp4.example.com.	IN	A	192.168.1.11 
master2.ocp4.example.com.	IN	A	192.168.1.12 
;
worker0.ocp4.example.com.	IN	A	192.168.1.13 
worker1.ocp4.example.com.	IN	A	192.168.1.14
;
;
```

<br><br>
## Bastion(또는 Installer pod) 준비 절차

### 사전 설치된 Packages 확인 (registry.redhat.io/ubi8/ubi 기준 추가 필요)

```
$ dnf info nmstate bind-utils iputils iproute coreos-installer
```

### 사전 다운로드된 tools 확인

```
## openshift client 버전 확인
$ oc version

## openshift installer 버전 확인
$ openshift-install version
```

### DNS 확인

```
## api DNS 주소 확인
$ nslookup api.ocp4.example.com
```

### ping 테스트

```
## machine network default gateway ping 테스트
$ ping -c3 192.168.1.1
```

### sshKey 확인

```
$ SshKey="$(cat /root/.ssh/id_rsa.pub)"
$ echo $SshKey
```

### additionalTrustBundle 확인

```
## mirror registry 의 CA trust 파일 확인
$ additionalTrustBundle="/root/additional-trust-bundle"
$ sed 's/^/    /g' /etc/pki/ca-trust/source/anchors/registry.crt > ${additionalTrustBundle}
$ cat ${additionalTrustBundle}
```

### image info 확인

```
## image repository 접근 확인
$ Repository="registry.example.com:5000/release416-12-12"
$ pullSecret="/root/pull-secret" ## registry authentication 파일
$ cat ${pullSecret}
$ ReleaseVersion="4.16.12"
$ update-ca-trust
$ oc image info -a ${PullSecret} ${Repository}/openshift/release-images:${ReleaseVersion}-x86_64
```

### install config 준비

```
$ BaseDomain="example.com"
$ WorkerRelicas="2"
$ ClusterName="ocp4"
$ ClusterNetworkCidr="10.128.0.0/14"
$ MachineNetworkCidr="192.168.1.0/24"
$ ApiVIP="192.168.1.7"
$ IngressVIP="192.168.1.8"

## operator repository
$ OperatorRepo="registry.example.com:5000/olm-redhat"

## 인증 정보 생성
$ htpasswdSecret="/opt/openshift/auth/htpasswd" ## htpasswd authentication 파일
$ htpasswd -Bbc ${htpasswdSecret} admin <password>

$ INSTALL_DIR="/root/${ClusterName}"
$ rm -rf ${INSTALL_DIR}
$ mkdir ${INSTALL_DIR}
$ cat > ${INSTALL_DIR}/install-config.yaml <<EOF
apiVersion: v1
baseDomain: ${BaseDomain}
compute:
- name: worker
  replicas: ${WorkerRelicas}
controlPlane:
  name: master
  replicas: 3
metadata:
  name: ${ClusterName}
networking:
  networkType: OVNKubernetes
  clusterNetwork:
  - cidr: ${ClusterNetworkCidr}
    hostPrefix: 23
  serviceNetwork:
  - 172.30.0.0/16
  machineNetwork:
  - cidr: ${MachineNetworkCidr}
platform:
  vsphere:
    apiVIPs:
    - ${ApiVIP}
    ingressVIPs:
    - ${ingressVIP}
pullSecret: '$(cat ${pullSecret})'
sshKey: |
  ${SshKey}
imageContentSources:
- mirrors:
  - ${Repository}/openshift/release-images
  source: quay.io/openshift-release-dev/ocp-release
- mirrors:
  - ${Repository}/openshift/release
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
additionalTrustBundle: |
$(cat ${additionalTrustBundle})
EOF
```

### agent config 구성

```
$ AdditionalNTPSource="192.168.1.3"
$ DeviceName="/dev/disk/by-path/pci-0000:05:00.0"
$ DnsServer="192.168.1.5"
$ Gateway="192.168.1.1"
$ MacAddress_m0="00:ef:50:30:f0:b0"
$ MacAddress_m1="00:ef:50:30:f1:b0"
$ MacAddress_m2="00:ef:50:30:f2:b0"
$ MacAddress_w0="00:ef:50:30:f3:b0"
$ MacAddress_w1="00:ef:50:30:f4:b0"
$ Ip_m0="192.168.1.10"
$ Ip_m1="192.168.1.11"
$ Ip_m2="192.168.1.12"
$ Ip_w0="192.168.1.13"
$ Ip_w1="192.168.1.14"

$ cat > ${INSTALL_DIR}/agent-config.yaml <<EOF
apiVersion: v1alpha1
kind: AgentConfig
metadata:
  name: ${ClusterName}
additionalNTPSources:
- ${AdditionalNTPSource}
hosts:
- hostname: master0.${ClusterName}.${BaseDomain}
  role: master
  rootDeviceHints:
    deviceName: ${DeviceName}
  interfaces:
  - name: enp1s0
    macAddress: ${MacAddress_m0}
  networkConfig:
    interfaces:
    - name: enp1s0
      type: ethernet
      state: up
      ipv4:
        enabled: true
        address:
        - ip: ${Ip_m0}
          prefix-length: 24
        dhcp: false
      ipv6:
        enabled: false
    dns-resolver:
      config:
        server:
        - ${DnsServer}
    routes:
      config:
      - destination: 0.0.0.0/0
        next-hop-address: ${Gateway}
        next-hop-interface: enp1s0
        table-id: 254
- hostname: master1.${ClusterName}.${BaseDomain}
  role: master
  rootDeviceHints:
    deviceName: ${DeviceName}
  interfaces:
  - name: enp1s0
    macAddress: ${MacAddress_m1}
  networkConfig:
    interfaces:
    - name: enp1s0
      type: ethernet
      state: up
      ipv4:
        enabled: true
        address:
        - ip: ${Ip_m1}
          prefix-length: 24
        dhcp: false
      ipv6:
        enabled: false
    dns-resolver:
      config:
        server:
        - ${DnsServer}
    routes:
      config:
      - destination: 0.0.0.0/0
        next-hop-address: ${Gateway}
        next-hop-interface: enp1s0
        table-id: 254
- hostname: master2.${ClusterName}.${BaseDomain}
  role: master
  rootDeviceHints:
    deviceName: ${DeviceName}
  interfaces:
  - name: enp1s0
    macAddress: ${MacAddress_m2}
  networkConfig:
    interfaces:
    - name: enp1s0
      type: ethernet
      state: up
      ipv4:
        enabled: true
        address:
        - ip: ${Ip_m2}
          prefix-length: 24
        dhcp: false
      ipv6:
        enabled: false
    dns-resolver:
      config:
        server:
        - ${DnsServer}
    routes:
      config:
      - destination: 0.0.0.0/0
        next-hop-address: ${Gateway}
        next-hop-interface: enp1s0
        table-id: 254
- hostname: worker0.${ClusterName}.${BaseDomain}
  role: worker
  rootDeviceHints:
    deviceName: ${DeviceName}
  interfaces:
  - name: enp1s0
    macAddress: ${MacAddress_w0}
  networkConfig:
    interfaces:
    - name: enp1s0
      type: ethernet
      state: up
      ipv4:
        enabled: true
        address:
        - ip: ${Ip_w0}
          prefix-length: 24
        dhcp: false
      ipv6:
        enabled: false
    dns-resolver:
      config:
        server:
        - ${DnsServer}
    routes:
      config:
      - destination: 0.0.0.0/0
        next-hop-address: ${Gateway}
        next-hop-interface: enp1s0
        table-id: 254
- hostname: worker1.${ClusterName}.${BaseDomain}
  role: worker
  rootDeviceHints:
    deviceName: ${DeviceName}
  interfaces:
  - name: enp1s0
    macAddress: ${MacAddress_w1}
  networkConfig:
    interfaces:
    - name: enp1s0
      type: ethernet
      state: up
      ipv4:
        enabled: true
        address:
        - ip: ${Ip_w1}
          prefix-length: 24
        dhcp: false
      ipv6:
        enabled: false
    dns-resolver:
      config:
        server:
        - ${DnsServer}
    routes:
      config:
      - destination: 0.0.0.0/0
        next-hop-address: ${Gateway}
        next-hop-interface: enp1s0
        table-id: 254
EOF
```

<br><br>
## Installer 실행

### agent cluster-manifests 생성

```
$ export OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE=${Repository}/openshift/release-images:${ReleaseVersion}-x86_64
$ openshift-install agent create cluster-manifests --log-level debug --dir ${INSTALL_DIR}
```

### cluster-manifests 파일들 추가

```
$ mkdir ${INSTALL_DIR}/openshift

## sample config 삭제
$ cat > ${INSTALL_DIR}/openshift/02-sample-config.yml<<EOF
apiVersion: samples.operator.openshift.io/v1
kind: Config
metadata:
  name: cluster
spec:
  architectures:
  - x86_64
  managementState: Removed
EOF

## registry ca trust configmap 생성
cat > ${INSTALL_DIR}/openshift/registry-config.yaml<<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: registry-config
  namespace: openshift-config
data:
  ${Repository%%:*}..$(echo ${Repository%%/*} | cut -d: -f2): |
$(cat ${additionalTrustBundle})
  updateservice-registry: |
$(cat ${additionalTrustBundle})
EOF

## image.pulling 을 위한 trust ca 등록
cat > ${INSTALL_DIR}/openshift/imageconfig.yaml<<EOF
apiVersion: config.openshift.io/v1
kind: Image
metadata:
  name: cluster
spec:
  additionalTrustedCA:
    name: registry-config
EOF

## operator hub off
$ cat > ${INSTALL_DIR}/openshift/02-operatorhub-config.yml<<EOF
apiVersion: config.openshift.io/v1
kind: OperatorHub
metadata:
  name: cluster
spec:
  sources:
  - disabled: true
    name: certified-operators
  - disabled: true
    name: community-operators
  - disabled: true
    name: redhat-marketplace
  - disabled: true
    name: redhat-operators
EOF

## chrony.conf 내용 준비
CHRN=`base64 -w0 <<EOF
server ${AdditionalNTPSource} iburst
driftfile /var/lib/chrony/drift
rtcsync
makestep 1.0 3
logdir /var/log/chrony
EOF`

## master 용 chrony.conf 적용
cat > ${INSTALL_DIR}/openshift/99-master-chrony.yaml<<EOF
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: 99-master-chrony
spec:
  config:
    ignition:
      version: 3.4.0
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,${CHRN}
        mode: 420
        overwrite: true
        path: /etc/chrony.conf
EOF

## worker 용 chrony.conf 적용
cat > ${INSTALL_DIR}/openshift/99-worker-chrony.yaml<<EOF
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: 99-worker-chrony
spec:
  config:
    ignition:
      version: 3.4.0
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,${CHRN}
        mode: 420
        overwrite: true
        path: /etc/chrony.conf
EOF

## infra mcp 생성
cat > ${INSTALL_DIR}/openshift/mcp-infra.yaml<<EOF
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfigPool
metadata:
  name: infra
spec:
  machineConfigSelector:
    matchExpressions:
      - {key: machineconfiguration.openshift.io/role, operator: In, values: [worker,infra]}
  nodeSelector:
    matchLabels:
      node-role.kubernetes.io/infra: ""
EOF

## master 에 kernel arguments 추가
cat > ${INSTALL_DIR}/openshift/10-master-kernel-arguments.yaml<<EOF
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: 10-master-kernel-arguments
spec:
  config:
    ignition:
      version: 3.4.0
  kernelArguments:
  - sd_mod.probe=sync
EOF

## worker 에 kernel arguments 추가
cat > ${INSTALL_DIR}/openshift/10-worker-kernel-arguments.yaml<<EOF
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: 10-worker-kernel-arguments
spec:
  config:
    ignition:
      version: 3.4.0
  kernelArguments:
  - sd_mod.probe=sync
EOF

## master 에 reserved 자원 할당 추가
cat > ${INSTALL_DIR}/openshift/02-master-dynamic-kubeletconfig.yml<<EOF
apiVersion: machineconfiguration.openshift.io/v1
kind: KubeletConfig
metadata:
  name: master-dynamic-kubeletconfig
spec:
  autoSizingReserved: true
  machineConfigPoolSelector:
    matchLabels:
      pools.operator.machineconfiguration.openshift.io/master: ""
EOF

## worker 에 reserved 자원 할당 추가
cat > ${INSTALL_DIR}/openshift/02-worker-dynamic-kubeletconfig.yml<<EOF
apiVersion: machineconfiguration.openshift.io/v1
kind: KubeletConfig
metadata:
  name: worker-dynamic-kubeletconfig
spec:
  autoSizingReserved: true
  machineConfigPoolSelector:
    matchLabels:
      pools.operator.machineconfiguration.openshift.io/worker: ""
EOF

## master 에 timezone 설정
cat > ${INSTALL_DIR}/openshift/20-master-custom-timezone.yml<<EOF
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: 20-master-custom-timezone
spec:
  config:
    ignition:
      version: 3.4.0
    systemd:
      units:
      - contents: |
          [Unit]
          Description=set timezone
          After=network-online.target

          [Service]
          Type=oneshot
          ExecStart=timedatectl set-timezone Asia/Seoul

          [Install]
          WantedBy=multi-user.target
        enabled: true
        name: custom-timezone.service
EOF

## worker 에 timezone 설정
cat > ${INSTALL_DIR}/openshift/02-worker-custom-timezone.yml<<EOF
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: 20-worker-custom-timezone
spec:
  config:
    ignition:
      version: 3.4.0
    systemd:
      units:
      - contents: |
          [Unit]
          Description=set timezone
          After=network-online.target

          [Service]
          Type=oneshot
          ExecStart=timedatectl set-timezone Asia/Seoul

          [Install]
          WantedBy=multi-user.target
        enabled: true
        name: custom-timezone.service
EOF

## master 에 additional disk 를 /var/lib/containers 로 설정
cat > ${INSTALL_DIR}/openshift/98-master-var-mount.yaml<<EOF
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: 98-master-var-mount
spec:
  config:
    ignition:
      version: 3.4.0
    storage:
      disks:
        - device: /dev/disk/by-path/pci-0000:06:00.0
          partitions:
            - label: data-1
          wipeTable: true
      filesystems:
        - device: /dev/disk/by-partlabel/data-1
          format: xfs
          path: /var/lib/containers
          wipeFilesystem: true
    systemd:
      units:
        - contents: |-
            [Unit]
            Before=local-fs.target
            Requires=systemd-fsck@dev-disk-by\x2dpartlabel-data\x2d1.service
            After=systemd-fsck@dev-disk-by\x2dpartlabel-data\x2d1.service

            [Mount]
            Where=/var/lib/containers
            What=/dev/disk/by-partlabel/data-1
            Type=xfs

            [Install]
            RequiredBy=local-fs.target
          enabled: true
          name: var-lib-containers.mount
EOF

## worker 에 additional disk 를 /var/lib/containers 로 설정
cat > ${INSTALL_DIR}/openshift/98-worker-var-mount.yaml<<EOF
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: 98-worker-var-mount
spec:
  config:
    ignition:
      version: 3.4.0
    storage:
      disks:
        - device: /dev/disk/by-path/pci-0000:06:00.0
          partitions:
            - label: data-1
          wipeTable: true
      filesystems:
        - device: /dev/disk/by-partlabel/data-1
          format: xfs
          path: /var/lib/containers
          wipeFilesystem: true
    systemd:
      units:
        - contents: |-
            [Unit]
            Before=local-fs.target
            Requires=systemd-fsck@dev-disk-by\x2dpartlabel-data\x2d1.service
            After=systemd-fsck@dev-disk-by\x2dpartlabel-data\x2d1.service

            [Mount]
            Where=/var/lib/containers
            What=/dev/disk/by-partlabel/data-1
            Type=xfs

            [Install]
            RequiredBy=local-fs.target
          enabled: true
          name: var-lib-containers.mount
EOF

## redhat operator mirror repository 설정
cat > ${INSTALL_DIR}/openshift/idms-redhat-operator.yml<<EOF
apiVersion: config.openshift.io/v1
kind: ImageDigestMirrorSet
metadata:
  name: redhat
spec:
  imageDigestMirrors:
  - mirrors:
    - ${OperatorRepo}
    source: registry.redhat.io
EOF

## redhat operator catalog source 설정
cat > ${INSTALL_DIR}/openshift/cs-redhat-operator-index.yml<<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: cs-redhat-operator-index
  namespace: openshift-marketplace
spec:
  image: ${OperatorRepo}/redhat/redhat-operator-index:v${ReleaseVersion%.*}
  sourceType: grpc
  updateStrategy:
    registryPoll:
      interval: 20m
EOF

## ingress conroller 설정
cat > ${INSTALL_DIR}/openshift/ingress-controller.yml<<EOF
apiVersion: operator.openshift.io/v1
kind: IngressController
metadata:
  name: default
  namespace: openshift-ingress-operator
spec:
  nodePlacement:
    nodeSelector:
      matchLabels:
        node-role.kubernetes.io/infra: ""
    tolerations:
    - effect: NoSchedule
      operator: Exists
      key: node-role.kubernetes.io/infra
EOF

## htpasswd secret 설정
cat > ${INSTALL_DIR}/openshift/htpass-secret.yml<<EOF
apiVersion: v1
data:
  htpasswd: $(base64 -w0 ${htpasswdSecret})
kind: Secret
metadata:
  name: htpass-secret
  namespace: openshift-config
EOF

## oauth cluster 설정
cat > ${INSTALL_DIR}/openshift/oauth-cluster.yml<<EOF
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - htpasswd:
      fileData:
        name: htpass-secret
    mappingMethod: claim
    name: htpass-login
    type: HTPasswd
EOF

## cluster-admin rolebinding 설정
cat > ${INSTALL_DIR}/openshift/clusterrolebinding-cluster-admin0.yml<<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-admin0
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: admin
EOF

## dns operator toleration 설정
cat > ${INSTALL_DIR}/openshift/dns-operator.yml<<EOF
apiVersion: operator.openshift.io/v1
kind: DNS
metadata:
  name: default
spec:
  nodePlacement:
    tolerations:
    - effect: NoSchedule
      operator: Exists
      key: node-role.kubernetes.io/infra
EOF

## cluster-monitoring-config 설정
cat > ${INSTALL_DIR}/openshift/cluster-monitoring-config.yml<<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-monitoring-config
  namespace: openshift-monitoring
data:
  config.yaml: |
    prometheusOperator:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
      tolerations:
      - key: node-role.kubernetes.io/infra
        operator: Exists
        effect: NoSchedule
    prometheusK8s:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
      tolerations:
      - key: node-role.kubernetes.io/infra
        operator: Exists
        effect: NoSchedule
    alertmanagerMain:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
      tolerations:
      - key: node-role.kubernetes.io/infra
        operator: Exists
        effect: NoSchedule
    kubeStateMetrics:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
      tolerations:
      - key: node-role.kubernetes.io/infra
        operator: Exists
        effect: NoSchedule
    monitoringPlugin:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
      tolerations:
      - key: node-role.kubernetes.io/infra
        operator: Exists
        effect: NoSchedule
    openshiftStateMetrics:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
      tolerations:
      - key: node-role.kubernetes.io/infra
        operator: Exists
        effect: NoSchedule
    telemeterClient:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
      tolerations:
      - key: node-role.kubernetes.io/infra
        operator: Exists
        effect: NoSchedule
    metricsServer:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
      tolerations:
      - key: node-role.kubernetes.io/infra
        operator: Exists
        effect: NoSchedule
    thanosQuerier:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
      tolerations:
      - key: node-role.kubernetes.io/infra
        operator: Exists
        effect: NoSchedule
EOF

```

### agent image 생성
```
$ openshift-install agent create image --dir ${INSTALL_DIR} --log-level debug

```

<br><br>
## VM 노드 생성

### vm.create

```
## On the command line, power off and delete any preexisting virtual machines:
$ for VM in $(/usr/local/bin/govc ls /<datacenter>/vm/<folder_name>)
do
 	/usr/local/bin/govc vm.power -off $VM
 	/usr/local/bin/govc vm.destroy $VM
done

## Remove preexisting ISO images from the data store, if there are any:
$ govc datastore.rm -ds <iso_datastore> <image>

## Upload the Assisted Installer discovery ISO:
$ govc datastore.upload -ds <iso_datastore> agent.x86_64.iso

## Boot three control plane nodes:
$ govc vm.create -net.adapter <network_adapter_type> \
                 -disk.controller <disk_controller_type> \
                 -pool=<resource_pool> \
                 -c=16 \
                 -m=32768 \
                 -disk=120GB \
                 -disk-datastore=<datastore_file> \
                 -net.address="<nic_mac_address>" \
                 -iso-datastore=<iso_datastore> \
                 -iso="agent.x86_64.iso" \
                 -folder="<inventory_folder>" \
                 <hostname>.<cluster_name>.example.com

## Boot at least two worker nodes:
$ govc vm.create -net.adapter <network_adapter_type> \
                 -disk.controller <disk_controller_type> \
                 -pool=<resource_pool> \
                 -c=4 \
                 -m=8192 \
                 -disk=120GB \
                 -disk-datastore=<datastore_file> \
                 -net.address="<nic_mac_address>" \
                 -iso-datastore=<iso_datastore> \
                 -iso="agent.x86_64.iso" \
                 -folder="<inventory_folder>" \
                 <hostname>.<cluster_name>.example.com

## Ensure the VMs are running:
$  govc ls /<datacenter>/vm/<folder_name>

## After 2 minutes, shut down the VMs:
$ for VM in $(govc ls /<datacenter>/vm/<folder_name>)
do
     govc vm.power -s=true $VM
done
```

### disk.enableUUID 설정 및 시작

```
## Set the disk.enableUUID setting to TRUE:
$ for VM in $(govc ls /<datacenter>/vm/<folder_name>)
do
     govc vm.change -vm $VM -e disk.enableUUID=TRUE
done

## Restart the VMs:
$ for VM in $(govc ls /<datacenter>/vm/<folder_name>)
do
     govc vm.power -on=true $VM
done
```

<br><br>
## 설치 후 구성 설정
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
  annotations:
    managedcluster-import-controller.open-cluster-management.io/keeping-auto-import-secret: ""
stringData:
  autoImportRetry: "240"
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
$ oc get managedcluster ${ManagedCluster}

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
