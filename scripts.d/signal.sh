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

PREREQUISITES=('apt' 'ca-certificates' 'coreutils' 'curl' 'findutils' 'gnupg' 'grep' 'lsb-release' 'software-properties-common')
if ! check_prerequisites "${PREREQUISITES[@]}"
then
    echo "ERROR: Failed to comply to the prerequisites!"
    exit 11
fi

#Install workload
#Using xenial, though it is supposed to work for all versions...
if [[ $(find /etc/apt/ -name "*.list" | xargs cat | grep -c "signal") -eq 0 ]]
then
    echo "INFO: Adding Signal key file"
    curl -fsSL https://updates.signal.org/desktop/apt/keys.asc | sudo gpg --dearmor -o /usr/share/keyrings/signal-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/signal-archive-keyring.gpg] \
	    https://updates.signal.org/desktop/apt xenial main" | sudo tee /etc/apt/sources.list.d/signal.list > /dev/null
    run_privileged "Running apt update" "apt-get" "update"
    run_privileged "Installing Signal" "apt-get" "install" "-y" "signal-desktop"
else
    echo "INFO: Signal repository already exists"
fi
