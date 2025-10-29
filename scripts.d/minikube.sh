#!/bin/bash
SCRALL_DIR=$(readlink -f $(dirname $0)/..)
USER_HOME=$(echo ~)

COMMON="${SCRALL_DIR}/common.sh"
if [[ -f ${COMMON} ]]
then
	echo "INFO: Sourcing the ${COMMON} file"
	. ${COMMON}
else
	echo "ERROR: The file containing the common functions is not found!"
	exit 1
fi

PREREQUISITES=('apt-transport-https' 'coreutils' 'wget')
if ! check_prerequisites "${PREREQUISITES[@]}"
then
    echo "ERROR: Failed to comply to the prerequisites!"
    exit 11
fi

#Install workload
wget https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 -O ~/Downloads/minikube-linux-amd64
run_privileged "Install minikube" "install" "${USER_HOME}/Downloads/minikube-linux-amd64" "/usr/local/bin/minikube"
run_privileged "Delete minikube download" "rm" "-f" "${USER_HOME}/Downloads/minikube-linux-amd64"

wget "https://dl.k8s.io/release/$(wget -qO - https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl" -O ~/Downloads/kubectl
run_privileged "Install kubectl" "install" "-o" "root" "-g" "root" "-m" "0755" "${USER_HOME}/Downloads/kubectl" "/usr/local/bin/kubectl"
run_privileged "Delete kubectl download" "rm" "-f" "${USER_HOME}/Downloads/kubectl"
