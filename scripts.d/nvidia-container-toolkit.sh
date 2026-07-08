#!/bin/bash
INSTALL_TYPE="both"
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

PREREQUISITES=('apt' 'ca-certificates' 'coreutils' 'curl' 'findutils' 'gawk' 'gnupg' 'grep' 'lsb-release' 'software-properties-common')
if ! check_prerequisites "${PREREQUISITES[@]}"
then
    echo "ERROR: Failed to comply to the prerequisites!"
    exit 11
fi

#Install workload
if [[ $(find /etc/apt/ -name "*.list" | xargs cat | grep -c "nvidia-container-toolkit") -eq 0 ]]
then
    echo "INFO: Adding nvidia container toolkit  key file"
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
        | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
        | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
        | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    run_privileged "Running apt update" "apt-get" "update"
    run_privileged "Installing nvidia container toolkit" "apt-get" "install" "-y" "nvidia-container-toolkit"
    run_privileged "Configuring Docker to use the Nvidia container toolkit" "nvidia-ctk" "runtime" "configure" "--runtime=docker"
    run_privileged "Restarting docker" "systemctl" "restart" "docker"
else
    echo "INFO: Nvidia container toolkit repository already exists"
fi
