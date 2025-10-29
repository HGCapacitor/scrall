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
if [[ $(find /etc/apt/ -name "*.list" | xargs cat | grep -c "tuxedo") -eq 0 ]]
then
    echo "INFO: Download tuxedo key file installer"
    wget https://deb.tuxedocomputers.com/ubuntu/pool/main/t/tuxedo-archive-keyring/tuxedo-archive-keyring_2022.04.01~tux_all.deb -O ~/Downloads/tuxedo-archive-keyring.deb
    run_privileged "Install tuxedo key file" "dpkg" "-i" "${USER_HOME}/Downloads/tuxedo-archive-keyring.deb"
    run_privileged "Delete tuxedo key installer" "rm" "-f" "${USER_HOME}/Downloads/tuxedo-archive-keyring.deb"
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/tuxedo-archive-keyring.gpg] \
    https://deb.tuxedocomputers.com/$(lsb_release -is | awk '{print tolower($0)}') $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/spotify.list > /dev/null
    run_privileged "Running apt update" "apt-get" "update"
    run_privileged "Installing Tuxedo control center" "apt-get" "install" "-y" "tuxedo-control-center"
else
    echo "INFO: Tuxedo repository already exists"
fi
