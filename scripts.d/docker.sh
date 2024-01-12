#!/bin/bash
USER_TO_ADD_TO_DOCKER_GROUP=$(whoami)
INSTALL_TYPE="both"
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

usage() {
	echo -e "docker installation script for scrall installer"
	echo -e "This script does not support long options!"
	echo -e "USage: $0"
	echo -e "\t[-h]\t\t Provide this help"
	echo -e "\t[-i <choice>]\t Specify installation type [cli engine <both>]"
	echo -e "\t[-u <string>]\t Specify user name to add to the docker group <${USER_TO_ADD_TO_DOCKER_GROUP}>"
}

while getopts ":hi:u:" opt; do
	case "$opt" in
		h)
			usage
			exit 0
			;;
		i)
			INSTALL_TYPE=${OPTARG}
			case "${INSTALL_TYPE}" in
				"both"|"cli"|"engine")
					;;
				*)
	    				echo "ERROR: Unknown installation type <${INSTALL_TYPE}>"
					usage
					;;
			esac
			;;
		u)
			USER_TO_ADD_TO_DOCKER_GROUP=${OPTARG}
			;;
		:)
			echo "ERROR: option -$OPTARG requires an argument"
			usage
			exit 1
			;;
		\?)
			echo "ERROR: Invalid option -$OPTARG"
			usage
			exit 1
			;;
	esac
done

PREREQUISITES=('apt' 'ca-certificates' 'coreutils' 'curl' 'findutils' 'gawk' 'gnupg' 'grep' 'lsb-release' 'software-properties-common')
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
    https://download.docker.com/linux/$(lsb_release -is | awk '{print tolower($0)}') $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    run_privileged "Running apt update" "apt-get" "update"
    case "${INSTALL_TYPE}" in
        "cli")
            run_privileged "Installing docker cli" "apt-get" "install" "-y" "docker-ce-cli" "docker-compose-plugin"
            ;;
        "engine")
            run_privileged "Installing docker engine" "apt-get" "install" "-y" "docker-ce" "containerd.io"
	    if [[ $(groups ${USER_TO_ADD_TO_DOCKER_GROUP} | grep -c docker) -eq 0 ]]
	    then
            	run_privileged "Adding current user to the docker group" "usermod" "-aG" "docker" "${USER_TO_ADD_TO_DOCKER_GROUP}"
	    else
		echo "User ${USER_TO_ADD_TO_DOCKER_GROUP} is already member of the docker group"
	    fi
            ;;
        "both")
            run_privileged "Installing docker engine" "apt-get" "install" "-y" "docker-ce" "docker-ce-cli" "containerd.io" "docker-buildx-plugin" "docker-compose-plugin"
	    if [[ $(groups ${USER_TO_ADD_TO_DOCKER_GROUP} | grep -c docker) -eq 0 ]]
	    then
            	run_privileged "Adding current user to the docker group" "usermod" "-aG" "docker" "${USER_TO_ADD_TO_DOCKER_GROUP}"
	    else
		echo "User ${USER_TO_ADD_TO_DOCKER_GROUP} is already member of the docker group"
	    fi
            ;;
        *)
	    echo "ERROR: Unknown installation type <${INSTALL_TYPE}>"
            usage
            ;;
    esac
else
    echo "INFO: Docker repository already exists"
fi
