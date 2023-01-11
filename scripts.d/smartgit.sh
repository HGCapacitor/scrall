#!/bin/bash
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

PREREQUISITES=('wget')
if ! check_prerequisites "${PREREQUISITES[@]}"
then
    echo "ERROR: Failed to comply to the prerequisites!"
    exit 11
fi

#Install workload
export VERSION=$(wget -nv -qO -  https://www.syntevo.com/smartgit/changelog.txt | head -1 | awk '{print $2}' |  sed  --expression='s/\./_/g')
if [ -z ${VERSION} ]
then
	echo "ERROR: Failed to retrieve a version number for the latest SmartGit release!"
	exit 12
else
	echo "INFO: SmartGit-${VERSION} is available"
	run_privileged "Download SmartGit package" "wget" "https://www.syntevo.com/downloads/smartgit/smartgit-${VERSION}.deb"
	run_privileged "Running SmartGit installer" "dpkg" "-i" "smartgit-${VERSION}.deb"
	run_privileged "Fixing the package repsository..." "apt" "--fix-broken" "install"
	run_privileged "Delete SmartGit package" "rm"  "-f"  "smartgit-${VERSION}.deb" 
fi
