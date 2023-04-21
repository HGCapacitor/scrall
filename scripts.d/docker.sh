#!/bin/bash
SCRALL_DIR=$(readlink -f $(dirname $0)/..)

COMMON="${SCRALL_DIR}/scrall-common.sh"
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

if [[ $(find /etc/apt/ -name "*.list" | xargs cat | grep -c "docker") -eq 0 ]]
then
    echo "INFO: Adding docker key file"
    curl -fsSL https://download.docker.com/linux/$(lsb_release -is | awk '{print tolower($0)}')/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
    https://download.docker.com/linux/$(lsb_release -is) $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    run_privileged "Running apt update" "apt-get" "update"
    run_privileged "Installing docker" "apt-get" "install" "-y" "docker-ce" "docker-ce-cli" "containerd.io" "docker-compose"
    run_privileged "Adding current user to the docker group" "usermod" "-aG" "docker" "$(whoami)"
else
    echo "INFO: Docker repository already exists"
fi
