#!/bin/bash

set -o pipefail
set -x

# version
VERSION="1.0.1 03/2022"

# virtual network name
NETWORK_NAME="ocp-dev"

# image info
IMAGE_DIR="/images/"
IMAGE="rhcos-4.10.3-x86_64-live.x86_64.iso"
IMAGE_VARIANT="rhl8.0"

# VM image dir
VM_IMAGE_DIR="/var/lib/libvirt/images/"

# domain and cluster name
DOMAIN="ocp.lan"
CLUSTER="lab"

# install dir
INSTALL_DIR="/ocp-install"

# host info
HOST_MAC="52:54:00:4c:33:95"
HOST_INTERFACE="eno1"
IP_ADDRESS="192.168.122.1"
START_ADDRESS="192.168.122.2"
END_ADDRESS="192.168.122.254"

# nfs
NFS_SHARE_DIR="/share/registry"
HOST_BASE_ADDRESS="192.168.8.122"

# mac address setup
BOOTSTRAP='52:54:00:3f:de:37'
CP1='52:54:00:f5:9d:d4'
CP2='52:54:00:70:b9:af'
CP3='52:54:00:fd:6a:ca'
W1='52:54:00:bc:56:ff'
W2='52:54:00:4f:06:97'
W3='52:54:00:c3:45:ea'

# ip address setup
HOST_IP="192.168.122.1"
BOOTSTRAP_IP="192.168.122.253"
CP1_IP='192.168.122.2'
CP2_IP='192.168.122.3'
CP3_IP='192.168.122.4'
W1_IP='192.168.122.5'
W2_IP='192.168.122.6'
W3_IP='192.168.122.7'

# pull secret and ssh key
PULL_SECRET=~/Downloads/pull-secret
SSH_KEY=~/.ssh/id_rsa.pub

# http server file  directory
HTTPD_SERVER_FILES=/var/www/html/ocp

# master replicas
REPLICAS=1

# master schedulable
MASTER_SCHEDULABLE=yes

# hard coded server names and menu input
# leave these values as is - it could cause major mayhem

# NAME         VM NAME         MENU INPUT
# bootstrap -> ocp-bootstrap  bootstrap
# master 1  -> ocp-cp1         cp1
# master 2  -> ocp-cp2         cp2
# master 3  -> ocp-cp3         cp3
# worker 1  -> ocp-w1          w1
# worker 2  -> ocp-w2          w2
# worker 3  -> ocp-w3          w3

# once the vms have started use the coreos-installer command to point to the image and ignition files
# remember to change the worker.ign to master.ign for master
# and worker.ign to bootstrap.ign for bootstrap
# sudo coreos-installer install /dev/sda --ignition-url https://192.168.122.1:8080/ocp/worker.ign  --image-url http://192.168.122.1:8080/ocp/rhcos  --insecure-ignition -insecure

getMac () {
  case $1 in
    bootstrap)
      echo ${BOOTSTRAP}
    ;;
  cp1)
      echo ${CP1}
    ;;
  cp2)
      echo ${CP3}
    ;;
  cp3)
      echo ${CP3}
    ;;
  w1)
      echo ${W1}
    ;;
  w2)
      echo ${W2}
    ;;
  w3)
      echo ${W3}
    ;;
  esac
}

case ${1} in
  help)
    echo -e "usage : ./virt-env-install.sh [preflight,dnsconfig,haproxy,config,manifests,ignition,network,vm]"
    exit 0
  ;;
  preflight)
    # check for dnsmasq install
    # check for haproxy
    # check for httpd
    # check firewalld is enabled and running
    # check for nfs
    exit 0
  ;;
  dnsconfig)
    cat << EOF > dnsmasq.conf
    # Configuration file for dnsmasq.
    port=53
    bogus-priv
    no-poll
    user=dnsmasq
    group=dnsmasq
    bind-interfaces
    no-hosts
    # Include all files in /etc/dnsmasq.d except RPM backup files
    conf-dir=/etc/dnsmasq.d,.rpmnew,.rpmsave,.rpmorig
    interface=${HOST_INTERFACE}
    domain=${DOMAIN}
    expand-hosts
    address=/ocp-bootstrap.${CLUSTER}.${DOMAIN}/${BOOTSTRAP_IP}
    host-record=ocp-bootstrap.${CLUSTER}.${DOMAIN},${BOOTSTRAP_IP}
    address=/ocp-cp1.${CLUSTER}.${DOMAIN}/${CP1_IP}
    host-record=ocp-cp1.${CLUSTER}.${DOMAIN},${CP1_IP}
    address=/ocp-cp2.${CLUSTER}.${DOMAIN}/${CP2_IP}
    host-record=ocp-cp2.${CLUSTER}.${DOMAIN},${CP2_IP}
    address=/ocp-cp3.${CLUSTER}.${DOMAIN}/${CP3_IP}
    host-record=ocp-cp3.${CLUSTER}.${DOMAIN},${CP3_IP}
    address=/ocp-w1.${CLUSTER}.${DOMAIN}/${W1_IP}
    host-record=ocp-w1.${CLUSTER}.${DOMAIN},${W1_IP}
    address=/ocp-w2.${CLUSTER}.${DOMAIN}/${W2_IP}
    host-record=ocp-w2.${CLUSTER}.${DOMAIN},${W2_IP}
    address=/ocp-w3.${CLUSTER}.${DOMAIN}/${W3_ip}
    host-record=ocp-w3.${CLUSTER}.${DOMAIN},${W3_IP}
    address=/api.${CLUSTER}.${DOMAIN}/${HOST_IP}
    address=/api-int.${CLUSTER}.${DOMAIN}/${HOST_IP}
    address=/etcd-0.${CLUSTER}.${DOMAIN}/${CP1_IP}
    address=/etcd-1.${CLUSTER}.${DOMAIN}/${CP2_IP}
    address=/etcd-2.${CLUSTER}.${DOMAIN}/${CP3_IP}
    address=/.apps.${CLUSTER}.${DOMAIN}/${HOST_IP}
    srv-host=_etcd-server-ssl._tcp,etcd-0.${CLUSTER}.${DOMAIN},2380
    srv-host=_etcd-server-ssl._tcp,etcd-1.${CLUSTER}.${DOMAIN},2380
    srv-host=_etcd-server-ssl._tcp,etcd-2.${CLUSTER}.${DOMAIN},2380
    address=/oauth-openshift.apps.${CLUSTER}.${DOMAIN}/${HOST_IP}
    address=/console-openshift-console.apps.${CLUSTER}.${DOMAIN}/${HOST_IP}    
EOF
    sudo cp dnsmasq.conf /etc/dnsmasq.conf
    sudo /usr/sbin/dnsmqasq --conf-file=/etc/dnsmasq.conf
    exit 0
  ;;
haproxy)
  cat << EOF > haproxy.cfg
# Global settings
#---------------------------------------------------------------------
global
    maxconn     20000
    log         /dev/log local0 info
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    user        haproxy
    group       haproxy
    daemon

    # turn on stats unix socket
    stats socket /var/lib/haproxy/stats

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    log                     global
    mode                    http
    option                  httplog
    option                  dontlognull
    option http-server-close
    option redispatch
    option forwardfor       except 127.0.0.0/8
    retries                 3
    maxconn                 20000
    timeout http-request    10000ms
    timeout http-keep-alive 10000ms
    timeout check           10000ms
    timeout connect         40000ms
    timeout client          300000ms
    timeout server          300000ms
    timeout queue           50000ms

# Enable HAProxy stats
listen stats
    bind :9000
    stats uri /stats
    stats refresh 10000ms

# Kube API Server
frontend k8s_api_frontend
    bind :6443
    default_backend k8s_api_backend
    mode tcp

backend k8s_api_backend
    mode tcp
    balance source
    server      ocp-bootstrap $BOOTSTRAP_IP check
    server      ocp-cp1 $CP1_IP:6443 check
    server      ocp-cp2 $CP2_IP:6443 check
    server      ocp-cp3 $CP3_IP:6443 check

# OCP Machine Config Server
frontend ocp_machine_config_server_frontend
    mode tcp
    bind :22623
    default_backend ocp_machine_config_server_backend

backend ocp_machine_config_server_backend
    mode tcp
    balance source
    server      ocp-bootstrap $BOOTSTRAP_IP:22623 check
    server      ocp-cp1 $CP1_IP:22623 check
    server      ocp-cp2 $CP2_IP:22623 check
    server      ocp-cp3 $CP3_IP:22623 check

# OCP Ingress - layer 4 tcp mode for each. Ingress Controller will handle layer 7.
frontend ocp_http_ingress_frontend
    bind :80
    default_backend ocp_http_ingress_backend
    mode tcp

backend ocp_http_ingress_backend
    balance source
    mode tcp
    server      ocp-cp1 $CP1_IP:80 check
    server      ocp-cp2 $CP2_IP:80 check
    server      ocp-cp3 $CP3_IP:80 check
    server      ocp-w1 $W1_IP:80 check
    server      ocp-w2 $W2_IP:80 check
    server      ocp-w3 $W3_IP:80 check

frontend ocp_https_ingress_frontend
    bind *:443
    default_backend ocp_https_ingress_backend
    mode tcp

backend ocp_https_ingress_backend
    mode tcp
    balance source
    server      ocp-cp1 $CP1_IP:443 check
    server      ocp-cp2 $CP2_IP:443 check
    server      ocp-cp3 $CP3_IP:443 check
    server      ocp-w1 $W1_IP:443 check
    server      ocp-w2 $W2_IP:443 check
    server      ocp-w3 $W3_IP:443 check
EOF
  sudo cp haproxy.cfg /etc/haproxy/haproxy.cfg
  sudo systemctl restart haproxy
  exit 0
  ;;
  config)
    # we first ensure that the directories are created and/or exist
    mkdir -p ~/${INSTALL_DIR}
    # this is manual step - please ensure that you have the latest pull secret - else you will get cert expire errors
    cp ./install-config.yaml ~/${INSTALL_DIR}/
    rm -rf ~/$INSTALL_DIR/auth/
    rm -rf ~/$INSTALL_DIR/*.ign
    rm -rf ~/$INSTALL_DIR/*.json
    rm -rf ~/$INSTALL_DIR/.openshift*
    sed -i "s/update-replica/$REPLICAS/g" ~/${INSTALL_DIR}/install-config.yaml
    sed -i "s/update-domain/$DOMAIN/g" ~/${INSTALL_DIR}/install-config.yaml
    sed -i "s/update-cluster/$CLUSTER/g" ~/${INSTALL_DIR}/install-config.yaml
    SECRET=$(cat ${PULL_SECRET})
    echo -e "pullSecret: '$SECRET'" >> ~/${INSTALL_DIR}/install-config.yaml
    KEY=$(cat ${SSH_KEY})
    echo -e "sshKey: \"$KEY"\" >> ~/${INSTALL_DIR}/install-config.yaml
    exit 0
  ;;
  manifests)
    openshift-install create manifests --dir ~/${INSTALL_DIR}
    if [ "$MASTER_SCHEDULABLE" == "no" ];
    then
      sed -i 's/mastersSchedulable: true/mastersSchedulable: false/' ~/${INSTALL_DIR}/manifests/cluster-scheduler-02-config.yml
    fi
    exit 0
  ;;
  ignition)
    openshift-install create ignition-configs --dir ~/${INSTALL_DIR}
    exit 0
  ;;
  copy)
    # first ensure that both manifests and ignition are completed before copying
    rm -rf $HTTPD_SERVER_FILES/auth/
    rm -rf $HTTPD_SERVER_FILES/*.ign
    rm -rf $HTTPD_SERVER_FILES/*.json
    rm -rf $HTTPD_SERVER_FILES/.openshift*
    cp -r ~/${INSTALL_DIR}/* ${HTTPD_SERVER_FILES}/
    chmod -R 777 ${HTTPD_SERVER_FILES}/
    sudo systemctl restart httpd
  ;;
  network)
    # create network
    echo -e "${VERSION}"
    echo -e "creating virtual network"
    cat << EOF > network.xml
    <network connections='7'>
        <name>${NETWORK_NAME}</name>
        <forward mode='nat'>
              <nat>
            <port start='1024' end='65535'/>
              </nat>
        </forward>
        <bridge name='virbr0' stp='on' delay='0'/>
        <mac address='$HOST_MAC'/>
        <domain name='$NETWORK_NAME' localOnly='yes'/>
        <dns>
            <host ip='$HOST_IP'>
                <hostname>gateway</hostname>
            </host>
        </dns>
        <ip address='$IP_ADDRESS' netmask='255.255.255.0'>
              <dhcp>
            <range start='$START_ADDRESS' end='$END_ADDRESS'/>
            <host mac='$BOOTSTRAP' ip='$BOOTSTRAP_IP'/>
            <host mac='$CP1' ip='$CP1_IP'/>
            <host mac='$CP2' ip='$CP2_IP'/>
            <host mac='$CP3' ip='$CP3_IP'/>
            <host mac='$W1' ip='$W1_IP'/>
            <host mac='$W2' ip='$W2_IP'/>
            <host mac='$W3' ip='$W3_IP'/>
              </dhcp>
        </ip>
    </network>
EOF
    sudo virsh net-create network.xml
    exit 0
  ;;
  firewall)
    sudo firewall-cmd --add-port=6443/tcp --zone=internal --permanent # kube-api-server on control plane nodes
    sudo firewall-cmd --add-port=6443/tcp --zone=external --permanent # kube-api-server on control plane nodes
    sudo firewall-cmd --add-port=6443/tcp --zone=libvirt --permanent # kube-api-server on control plane nodes
    sudo firewall-cmd --add-port=22623/tcp --zone=internal --permanent # machine-config server
    sudo firewall-cmd --add-port=22623/tcp --zone=libvirt --permanent # machine-config server
    sudo firewall-cmd --add-service=http --zone=internal --permanent # web services hosted on worker nodes
    sudo firewall-cmd --add-service=http --zone=external --permanent # web services hosted on worker nodes
    sudo firewall-cmd --add-service=http --zone=libvirt --permanent # web services hosted on worker nodes
    sudo firewall-cmd --add-service=https --zone=internal --permanent # web services hosted on worker nodes
    sudo firewall-cmd --add-service=https --zone=external --permanent # web services hosted on worker nodes
    sudo firewall-cmd --add-service=https --zone=libvirt --permanent # web services hosted on worker nodes
    sudo firewall-cmd --add-port=9000/tcp --zone=external --permanent # HAProxy Stats
    sudo firewall-cmd --reload
  ;;
  vm)
    # note that network should be enabled and setup before executing vm install
    # once the install for all the vm's has completed shut the vm's down
    # then restart them and move on to ocp-install
    if [ "$#" -ne 3 ];
    then
        echo -e "vm type parameter needs to be specified"
        echo -e "select one [bootstrap,cp1,cp2,cp3,w1,w2,w3]"
      exit 0
    fi
    echo -e "${VERSION}"
    echo -e "installing $2 vm"
    MAC=$(getMac $2)
    if [ "$3" == "dry-run" ];
    then
       echo -e "sudo virt-install --connect qemu:///system --virt-type kvm --name ocp-$2 --ram 16000 --disk path=${VM_IMAGE_DIR}ocp-$2.img,size=100 --vcpu 4 --vnc --cdrom ${IMAGE_DIR}${IMAGE} --network network=${NETWORK_NAME},mac=${MAC} --os-variant ${IMAGE_VARIANT}"
    else
        sudo virt-install --connect qemu:///system --virt-type kvm --name ocp-$2 --ram 16000 --disk path=${VM_IMAGE_DIR}ocp-$2.img,size=100 --vcpu 4 --vnc --cdrom ${IMAGE_DIR}${IMAGE} --network network=${NETWORK_NAME},mac=${MAC} --os-variant ${IMAGE_VARIANT}
    fi
    exit 0
  ;;
  ocp-install)
    if [ "$#" -ne 2 ];
    then
        echo -e "usage: ocp-install [bootstrap,install]"
        exit 0
    fi
    openshift-install --dir ~$INSTALL_DIR wait-for ${2}-complete --log-level=debug
    exit 0
  ;;
  approve-certs)
    # approve pending csr
    oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs oc adm certificate approve
    exit 0
  ;;
  image-registry)
    
    # before using this section execute the following
    # oc edit configs.imageregistry.operator.openshift.io
    # update the managementState to
    # managementState: Managed
    # update the storage sectio to
    # storage:
    #   pvc:
    #     claim: # leave the claim blank
    # save when completed

    # create storage class and pv
    echo -e "${VERSION}"
    echo -e "creating storageclass"
    cat << EOF > storageclass.yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: sc-nfs
provisioner: ocp-install/external-nfs
parameters:
  path: ${NFS_SHARE_DIR}
  readOnly: 'false'
  server: ${HOST_BASE_ADDRESS}
reclaimPolicy: Retain
volumeBindingMode: Immediate
EOF

    echo -e "${VERSION}"
    echo -e "creating pv"
    cat << EOF > pv.yaml
kind: PersistentVolume
apiVersion: v1
metadata:
  name: registry-pv
spec:
  capacity:
    storage: 100Gi
  nfs:
    server: ${HOST_IP}
    path: ${HOST_BASE_ADDRESS}
  accessModes:
    - ReadWriteMany
  claimRef:
    kind: PersistentVolumeClaim
    namespace: openshift-image-registry
    name: image-registry-storage
  persistentVolumeReclaimPolicy: Retain
  storageClassName: sc-nfs
  volumeMode: Filesystem
EOF
  oc create -f storageclass.yaml
  oc create -f pv.yaml
  ;;
esac

