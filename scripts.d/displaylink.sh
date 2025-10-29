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

PREREQUISITES=('apt' 'ca-certificates' 'coreutils' 'curl' 'findutils' 'gnupg' 'grep' 'lsb-release' 'software-properties-common')
if ! check_prerequisites "${PREREQUISITES[@]}"
then
    echo "ERROR: Failed to comply to the prerequisites!"
    exit 11
fi

#Install workload
if [[ $(find /etc/apt/ -name "*.list" | xargs cat | grep -c "display-link") -eq 0 ]]
then
    echo "INFO: Download synaptics(displaylink) key file installer"
    wget https://www.synaptics.com/sites/default/files/Ubuntu/pool/stable/main/all/synaptics-repository-keyring.deb -O ~/Downloads/synaptics-repository-keyring.deb
    run_privileged "Install synaptics(displaylink) key file" "apt" "install" "${USER_HOME}/Downloads/synaptics-repository-keyring.deb"
    run_privileged "Delete synaptics(displaylink) key installer" "rm" "-f" "${USER_HOME}/Downloads/synaptics-repository-keyring.deb"
    run_privileged "Running apt update" "apt-get" "update"
    run_privileged "Installing synaptics display-link" "apt-get" "install" "-y" "displaylink-driver"
else
	echo "INFO: Synaptics(displaylink) repository already exists"
fi
