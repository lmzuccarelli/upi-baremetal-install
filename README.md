# Overview 

**ocp-baremetal-install**

A simple (naive) script to setup vm networking, vm's and install rhcos on the vm's  for a minimal openshift install 

## Document

Please refer to this [document](https://docs.google.com/document/d/19QjzNBDRgNiTk-LGki_xpi-lv8i_LRgf3dpOHSQ-_YI/edit) - RedHat access only 

## RedHat Documentation

Please refer to this [link](https://docs.openshift.com/container-platform/4.7/installing/installing_bare_metal/installing-bare-metal.html)

### Description

This is a simple helper script that will make the install of a multi-node or single node openshift cluster simpler
Its naive (it has manual steps and mauybe at a  later stage will be fully automated)

### Usage

A simple workflow 

```sh

./virt-env-install.sh config
./virt-env-install.sh dnsconfig
# stop and check/test your dns setup - refer to document
./virt-env-install.sh haproxy
./virt-env-install.sh firewall
./virt-env-install.sh network
./virt-env-install.sh manifests
./virt-env-install.sh ignition
./virt-env-install.sh copy

```

stop and install on each vm (via console) using 

- for bootstrap

```sh
sudo coreos-installer install /dev/vda --ignition-url http://xxx:8080/okd/bootstrap.ign --image-url http://xxx:8080/okd/fedora-coreos --insecure-ignition --insecure
```

- for master/worker

```sh
sudo coreos-installer install /dev/vda --ignition-url http://xxx:8080/okd/master.ign --image-url http://xxx:8080/okd/fedora-coreos --insecure-ignition --insecure
```

reboot all images once install is completed

continue with the install 

```sh
./virt-env-install.sh vm bootstrap ok (repeat this for each vm needed)
./virt-env-install.sh vm cp1 ok (repeat this for each vm needed)
./virt-env-install.sh ocp-install bootstrap
./virt-env-install.sh ocp-install install


```

### Acknowledgement

Thanks to Ryan Hay for his work on [ocp4-metal-install](https://github.com/ryanhay/ocp4-metal-install") 
