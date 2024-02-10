#Load the common functions
COMMON_FUNCTIONS="${SCRALL_DIR}/common.sh"
if [[ -f ${COMMON_FUNCTIONS} ]]
then
    echo "Sourcing the ${COMMON_FUNCTIONS} file"
    . ${COMMON_FUNCTIONS}
else
	echo "FATAL_ERROR: The file (${COMMON_FUNCTIONS}) containing the common functions is not found!"
    exit 10
fi

#Check the least required prerequisties
PREREQUISITES=('coreutils')
if ! check_prerequisites "${PREREQUISITES[@]}"
then
    echo "FATAL_ERROR: Failed to comply to the prerequisites!"
    exit 11
fi

#[START]Paranoia tests
if [[ "/" == ${PWD} ]]
then
    echo "FATAL_ERROR: Build cannot run from the root of the filesystem"
    echo "FATAL_ERROR: Please create a subdirectory to run from"
    exit 12
fi 
if [[ -z "${SCRALL_DIR}" ]]
then
    echo "FATAL_ERROR: SCRALL_DIR was not set"
    exit 13
else
    echo "INFO: Using (${SCRALL_DIR}) as project root"
fi
#[END]Paranoia tests

#Default settings
DOCKERIZE_PROJECT_DIR=${PWD}
DOCKERIZE_PROJECT_NAME=$(basename ${DOCKERIZE_PROJECT_DIR})
DOCKERIZE_DOCKER_FILE="${SCRALL_DIR}/scripts.d/scrall.dockerfile"
DOCKERIZE_DOCKER_IMAGE_TAG="${DOCKERIZE_PROJECT_NAME}-dockerize:latest"
DOCKERIZE_DOCKER_USER="scrall"
DOCKERIZE_DOCKER_GROUP="scrall"

#Reading overruled defaults
DOCKERIZE_CONFIG=dockerize.config
if [[ -f DOCKERIZE_CONFIG ]]
then
    echo "Sourcing the ${DOCKERIZE_CONFIG} file"
    . ${DOCKERIZE_CONFIG}
fi

#Show used settings to the user
echo "INFO: working from '${DOCKERIZE_PROJECT_DIR}'"
echo "INFO: using '${DOCKERIZE_PROJECT_NAME}' as the project name"
echo "INFO: using '${DOCKERIZE_DOCKER_FILE}' as the dockerfile"
echo "INFO: using '${DOCKERIZE_DOCKER_IMAGE_TAG}' as the docker container"
echo "INFO: using '${DOCKERIZE_DOCKER_USER}' as the docker user with group '${DOCKERIZE_DOCKER_GROUP}'"
