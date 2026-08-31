#!/bin/bash
USER_TO_ADD_TO_DOCKER_GROUP=$(whoami)
INSTALL_TYPE="both"
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

PREREQUISITES=('apt' 'ca-certificates' 'coreutils' 'curl' 'findutils' 'gawk' 'grep' 'software-properties-common')
if ! check_prerequisites "${PREREQUISITES[@]}"
then
    echo "ERROR: Failed to comply to the prerequisites!"
    exit 11
fi

#Install workload

SNAP="$(which snap)"
if [[ -n ${SNAP} ]]
then
        run_privileged "Remove snap version of docker" "${SNAP}" "remove" "docker" "--purge"
fi

if [[ $(find /etc/apt/ -name "*.sources" | xargs cat | grep -c "docker") -eq 0 ]]
then
    run_privileged "Installing keyring file" "curl" "-fsSL" "https://download.docker.com/linux/$(. /etc/os-release && echo ${NAME} | awk '{print tolower($0)}')/gpg" "-o" "/usr/share/keyrings/docker.asc"
    echo "Configuring the docker repository"
    printf '%s\n' \
        'Types: deb' \
        "URIs: https://download.docker.com/linux/$(. /etc/os-release && echo ${NAME} | awk '{print tolower($0)}')" \
        "Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")" \
        'Components: stable' \
        "Architecture: $(dpkg --print-architecture)" \
        'Signed-By: /usr/share/keyrings/docker.asc' \
        | sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null

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
