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

PREREQUISITES=('apt' 'coreutils' 'findutils' 'grep' 'software-properties-common')
if ! check_prerequisites "${PREREQUISITES[@]}"
then
    echo "ERROR: Failed to comply to the prerequisites!"
    exit 11
fi

#Install workload
if [[ $(find /etc/apt/ -name "*.list" | xargs cat | grep -c "nextcloud") -eq 0 ]]
then
        run_privileged "Adding nextcloud-client repository" "apt-add-repository" "-y" "ppa:nextcloud-devs/client"
        run_privileged "Running apt update" "apt-get update"
        run_privileged "Installing nextcloud-client" "apt-get install" "-y" "nextcloud-client"
else
        echo "INFO: Nextcloud-client repository already setup"
fi
