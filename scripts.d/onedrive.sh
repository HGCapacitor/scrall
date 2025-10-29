#!/bin/bash
SCRALL_DIR=$(readlink -f $(dirname $0)/..)
USER_GROUP=$(id -gn)

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
if [[ $(find /etc/apt/ -name "*.list" | xargs cat | grep -c "onedrive") -eq 0 ]]
then
    echo "INFO: Adding npreinig (onedrive) key file"
    curl -fsSL https://download.opensuse.org/repositories/home:/npreining:/debian-ubuntu-onedrive/x$(lsb_release -is)_$(lsb_release -rs)/Release.key | sudo gpg --dearmor -o /usr/share/keyrings/npreining-onedrive-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/npreining-onedrive-archive-keyring.gpg] \
    https://download.opensuse.org/repositories/home:/npreining:/debian-ubuntu-onedrive/x$(lsb_release -is)_$(lsb_release -rs) ./" | sudo tee /etc/apt/sources.list.d/onedrive.list > /dev/null
    run_privileged "Running apt update" "apt-get" "update"
    run_privileged "Installing VisualCode" "apt-get" "install" "-y" "onedrive"
    run_privileged "Create log directory" "mkdir" "-p" "/var/log/onedrive"
    run_privileged "Set group on log directory" "chgrp" "${USER_GROUP}" "/var/log/onedrive"
    run_privileged "Set access to log directory" "chmod" "775" "/var/log/onedrive"
else
    echo "INFO: onedrive repository already exists"
fi
#systemctl --user status onedrive
#onedrive --resync
#Copy config files to ~/.config/onedrive
#onedrive --resync --sync
#systemctl --user enable onedrive
#systemctl --user start onedrive
