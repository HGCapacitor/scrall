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
if [[ $(find /etc/apt/ -name "*.sources" | xargs cat | grep -c "vscode") -eq 0 ]]
then
    run_privileged "Adding Microsoft-VsCode key file" "curl" "-fsSL" "https://packages.microsoft.com/keys/microsoft.asc" "-o" "/usr/share/keyrings/microsoft.asc"
    printf '%s\n' \
        'Types: deb' \
        'URIs: https://packages.microsoft.com/repos/code' \
        'Suites: stable' \
        'Components: main' \
        'Signed-By: /usr/share/keyrings/microsoft.asc' \
	| sudo tee /etc/apt/sources.list.d/vscode.sources > /dev/null
    run_privileged "Running apt update" "apt-get" "update"
    run_privileged "Installing VisualCode" "apt-get" "install" "-y" "code"
else
    echo "INFO: VisualCode repository already exists"
fi
