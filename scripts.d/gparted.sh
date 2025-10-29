#!/bin/bash
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

PREREQUISITES=('apt' 'coreutils' 'findutils' 'grep' 'software-properties-common')
if ! check_prerequisites "${PREREQUISITES[@]}"
then
    echo "ERROR: Failed to comply to the prerequisites!"
    exit 11
fi

#Install workload
if [[ $(find /etc/apt/ -name "*.list" | xargs cat | grep -c "xtradeb") -eq 0 ]]
then
	run_privileged "Adding xtradeb (gparted) repository" "apt-add-repository" "-y" "ppa:xtradeb/apps"
        run_privileged "Running apt update" "apt-get" "update"
        run_privileged "Installing gparted" "apt-get" "install" "-y" "gparted"
else
	echo "INFO: xtradeb (gparted) repository already setup"
fi
