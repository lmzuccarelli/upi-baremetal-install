# ocp-baremetal-install
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
# Stop and check/test your dns setup - refer to document
./virt-env-install.sh haproxy
./virt-env-install.sh firewall
./virt-env-install.sh network
./virt-env-install.sh manifests
./virt-env-install.sh ignition
./virt-env-install.sh copy

# Stop and install on each vm using 
# for bootstrap
#   sudo coreos-installer install /dev/sda --ignition-url http://xxx:8080/okd/bootstrap.ign --image-url http://xxx:8080/okd/fedora-coreos --insecure-ignition --insecure*
# for worker
#   sudo coreos-installer install /dev/sda --ignition-url http://xxx:8080/okd/worker.ign --image-url http://xxx:8080/okd/fedora-coreos --insecure-ignition --insecure*

# Reboot all images once install is completed
# You can now continue with the install 

./virt-env-install.sh vm bootstrap ok (repeat this for each vm needed)
./virt-env-install.sh ocp-install bootstrap
./virt-env-install.sh ocp-install install


```

### Acknowledgement

Thanks to Ryan Hay for his work on [ocp4-metal-install](https://github.com/ryanhay/ocp4-metal-install") 
