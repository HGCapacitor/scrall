#!/bin/bash
SCRALL_DIR=$(dirname $(readlink -f $0))

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
	echo -e "scrall-1.0 scripted installation"
	echo -e "This script does not support long options!"
	echo -e "Usage: $0"
	echo -e "\t[-h]\tProvide this help"
	echo -e "\t[-e]\tExecute a specific installation script"
	echo -e "\t[-l]\tList all available installation scripts"
	echo -e "\t[-y]\tAnswer yes to everything"
}

PROGRAM_ACTION='DEFAULT'

while getopts ":e:hly" opt; do
	case "$opt" in
		e)
			PROGRAM_ACTION='EXECUTE_SCRIPT'
			INSTALL_SCRIPT=${OPTARG}
			;;
		h)
			usage
			exit 0
			;;
		l)
			PROGRAM_ACTION='LIST_SCRIPTS'
			;;
		y)
			AUTO_INSTALL="y"
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

SCRIPTS_DIR="${SCRALL_DIR}/scripts.d"

PREREQUISITES=('coreutils')
if ! check_prerequisites "${PREREQUISITES[@]}"
then
    echo "ERROR: Failed to comply to the prerequisites!"
    exit 2
fi

case ${PROGRAM_ACTION} in
	"LIST_SCRIPTS")
		if [ -d ${SCRIPTS_DIR} ];
		then
			list_scripts ${SCRIPTS_DIR}
			exit 0
		else
			echo "ERROR: There is no directory containing the installation scripts!"
			exit 2
		fi
		;;
	"EXECUTE_SCRIPT")
		COMMAND="${SCRIPTS_DIR}/${INSTALL_SCRIPT}.sh"
		execute_script ${COMMAND}
		exit 0
		;;
esac

#From here the DEFAULT program action
if [ -d ${SCRIPTS_DIR} ]
then
    for i in ${SCRIPTS_DIR}/*.sh; do
        if [ -x $i ]
        then
            SCRIPT_NAME=$(basename -s .sh ${i})
            read_boolean_answer "Do you want to execute ${SCRIPT_NAME} (y/n)?"
            if [ "x$REPLY" == "xy" ]
            then
                execute_script ${i}
            else
                echo "Skipping script: ${SCRIPT_NAME}"
            fi
        else
            echo "WARNING: File ${i} is not executable, please validate if this is correct"
        fi
    done
    unset i
else
    echo "WARNING: No scripts.d directory, please validate if this is correct"
fi
