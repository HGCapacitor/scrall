#!/bin/bash
USER_TO_ADD_TO_DOCKER_GROUP=$(whoami)
SCRALL_DIR=$(readlink -f $(dirname $0)/..)

COMMON="${SCRALL_DIR}/common.sh"
if [[ -f ${COMMON} ]]
then
	echo "INFO: Sourcing the ${COMMON} file"
	. ${COMMON}
else
	echo "ERROR: The file containing the common functions is not found!"
	exit 1
fi

PREREQUISITES=('apt' 'ca-certificates' 'coreutils' 'curl' 'findutils' 'gnupg' 'grep' 'lsb-release' 'software-properties-common')
if ! check_prerequisites "${PREREQUISITES[@]}"
then
    echo "ERROR: Failed to comply to the prerequisites!"
    exit 11
fi

#Install workload

if [[ $(find /etc/apt/ -name "*.list" | xargs cat | grep -c "kubernetes") -eq 0 ]]
then
    echo "INFO: Adding kubernetes key file"
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.36/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.36/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
    run_privileged "Running apt update" "apt-get" "update"
    run_privileged "Installing kubernetes" "apt-get" "install" "-y" "kubeadm" "kubelet" "kubectl" "containerd"
    run_privileged "Holding kubeadm kubelet and kubectl versions" "apt-mark" "hold" "kubeadm" "kubelet" "kubectl"
    echo "INFO: Configuring kuberenetes"
    run_privileged "Turning off the swap for predictable scheduling" "swapoff" "-a"
    sudo sed -i '/ swap / s/^(.*)$/#\1/g' /etc/fstab
    echo -e "overlay\nbr_netfilter" | sudo tee /etc/modules-load.d/k8s.conf
    run_privileged "Load overlay driver" "modprobe" "overlay"
    run_privileged "Load overlay netfilter" "modprobe" "br_netfilter"
    echo -e "net.bridge.bridge-nf-call-iptables = 1\nnet.bridge.bridge-nf-call-ip6tables = 1\nnet.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/k8s.conf
    sudo sysctl --system
    echo "INFO: Configuring containerd"
    run_privileged "Create containerd config folder" "mkdir" "-p" "/etc/containerd"
    containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
    sudo sed -i 's/SystemdCgroup = false/SystemdCgorup = true/g' /etc/containerd/config.toml
    run_privileged "Restart containerd" "systemctl" "restart" "containerd"
else
    echo "INFO: Kubernetes repository already exists"
fi
