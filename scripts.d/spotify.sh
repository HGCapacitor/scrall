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
if [[ $(find /etc/apt/ -name "*.list" | xargs cat | grep -c "spotify") -eq 0 ]]
then
    echo "INFO: Adding Spotify key file"
    curl -fsSL https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg | sudo gpg --dearmor -o /usr/share/keyrings/spotify-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/spotify-archive-keyring.gpg] \
    https://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list > /dev/null
    run_privileged "Running apt update" "apt-get" "update"
    run_privileged "Installing VisualCode" "apt-get" "install" "-y" "spotify-client"
else
    echo "INFO: Spotify repository already exists"
fi
