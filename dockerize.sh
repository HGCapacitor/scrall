#!/bin/bash
SCRALL_DIR="$(dirname $(readlink -f $0))"

DOCKERIZE_COMMON="${SCRALL_DIR}/dockerize-common.sh"
if [[ -f ${DOCKERIZE_COMMON} ]]
then
    echo "Sourcing the ${DOCKERIZE_COMMON} file"
    . ${DOCKERIZE_COMMON}
else
    echo "FATAL_ERROR: The file (${DOCKERIZE_COMMON}) containing the common functions is not found!"
    exit 1
fi

usage() {
    echo -e "dockerize-1.0"
    echo -e "This script does not support long options!"
    echo -e "Usage: $0"
    echo -e "\t[-h]\t\tProvides this help"
    echo -e "\t[-i]\t\tInteractive shell in the docker container"
}

PROGRAM_ACTION='DEFAULT'

while getopts ":his:" opt; do
    case "$opt" in
    h)
        usage
        exit 0
        ;;
    i)
        PROGRAM_ACTION='INTERACTIVE_SHELL'
        ;;
    :)
        echo "Error: Option -$OPTARG requires an argument"
        usage
        exit 1
        ;;
    \?)
        echo "Error: Invalid option -$OPTARG"
        usage
        exit 1
        ;;
    esac
done

docker_commit() {
    CONTAINER_ID=$(docker ps -a | grep ${DOCKERIZE_DOCKER_IMAGE_TAG} | head -n 1 | awk '{print $1}')
    if [[ -z "${CONTAINER_ID}" ]]
    then
        echo "Failed to get the container id!"
        echo "All your changes are lost!"
    else
        echo "Committing ${CONTAINER_ID}"
        docker commit $CONTAINER_ID "$DOCKERIZE_DOCKER_IMAGE_TAG"
    fi
}

docker_run() {
    local SCRIPT_WITH_PARAMS=${1}
    local DOCKER_SWITCHES=${2}

    if [ -z SSH_AUTH_SOCK ]
    then
        eval `ssh-agent`
        ssh-add -k
    fi

    if [[ -z "${SCRIPT_WITH_PARAMS}" ]]
    then
        docker run -it ${DOCKER_SWITCHES} -v ${SCRALL_DIR}:/scrall -v ${SSH_AUTH_SOCK}:/ssh-agent -e SSH_AUTH_SOCK=/ssh-agent -e DEBIAN_FRONTEND=noninteractive "$DOCKERIZE_DOCKER_IMAGE_TAG" /bin/bash
        return $?
    else
        docker run -it ${DOCKER_SWITCHES} -v ${SCRALL_DIR}:/scrall -v ${SSH_AUTH_SOCK}:/ssh-agent -e SSH_AUTH_SOCK=/ssh-agent -e DEBIAN_FRONTEND=noninteractive "$DOCKERIZE_DOCKER_IMAGE_TAG" /bin/bash -c "sudo chown -R ${BUILD_USER}:${BUILD_GROUP} ${MOUNTED_PROJECT_DIR}; cd ${MOUNTED_BUILD_DIR}; ${MOUNTED_SOURCES_DIR}/${BUILD_ENV_DIR}/${SCRIPT_WITH_PARAMS}"
        return $?
    fi
}

#Special program actions after which the script terminates
case ${PROGRAM_ACTION} in
    "INTERACTIVE_SHELL")
        docker_run
        docker_commit
        exit 0
        ;;
esac

#From here the DEFAULT program action
if ! which docker > /dev/null 2>&1
then
    echo "WARNING: Docker is not available, will try to install"
    execute_script "${SCRALL_DIR}/scripts.d/docker.sh"
    EXIT_CODE="$?"
    if [[ ${EXIT_CODE} -ne 0 ]]
    then
        echo "FATAL_ERROR: Could not install docker!"
        exit ${EXIT_CODE}
    fi
fi

if [[ $(docker image ls | grep -c ${DOCKERIZE_DOCKER_IMAGE_TAG/:/.*}) -eq 0 ]]
then
    echo "WARNING: ${DOCKERIZE_DOCKER_IMAGE_TAG} is not available, will try to build it"
    execute_script "${SCRALL_DIR}/scripts.d/build-docker-container.sh"
    EXIT_CODE="$?"
    if [[ ${EXIT_CODE} -ne 0 ]]
    then
        echo "FATAL_ERROR: Could not build the container!"
        exit ${EXIT_CODE}
    fi
fi
