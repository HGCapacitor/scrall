#!/bin/bash
SCRALL_DIR="$(readlink -f $(dirname $0)/..)"

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
    echo -e "build-container-1.0"
    echo -e "This script does not support long options!"
    echo -e "Usage: $0"
    echo -e "\t[-h]\t\tProvides this help"
    echo -e "\t[-t <string>]\tTag of the docker image {$DOCKERIZE_DOCKER_IMAGE_TAG}"
}

while getopts ":ht:" opt; do
    case "$opt" in
    h)
        usage
        exit 0
        ;;
    t)
        DOCKERIZE_DOCKER_IMAGE_TAG=${OPTARG}
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

if [[ $EUID -ne 0 ]]
then
    GUID=$(id -g)
    echo "Building docker image with user ${DOCKERIZE_DOCKER_USER} having user ids $EUID:$GUID"
    docker build --build-arg USER_NAME=${DOCKERIZE_DOCKER_USER} --build-arg USER_ID=$EUID --build-arg GROUP_NAME=${DOCKERIZE_DOCKER_GROUP} --build-arg USER_GID=$GUID -t "$DOCKERIZE_DOCKER_IMAGE_TAG" -f "$DOCKERIZE_DOCKER_FILE" .
    exit $?
else
    echo "Building docker image as root using default builder user and group ids"
    docker build -t "$DOCKERIZE_DOCKER_IMAGE_TAG" -f "$DOCKERIZE_DOCKER_FILE" .
    exit $?
fi
