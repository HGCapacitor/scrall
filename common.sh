#Common functions
run_privileged() {
    local COMMENT=${1}
    local COMMAND=${2}

    echo "INFO: ${COMMENT}"
    "${COMMAND}" "${@:3}"
    if [[ $? -ne 0 ]] && [[ $EUID -ne 0 ]] && which sudo > /dev/null 2>&1
    then
        echo "INFO: Failed to ${COMMENT}, trying with sudo"
        sudo "${COMMAND}" "${@:3}"
        if [[ $? -ne 0 ]]
        then
            echo "ERROR: Failed to ${COMMENT} with sudo"
            exit 1
        fi
    fi
    return 0
}

check_prerequisites() {
    PACKAGES=("${@}")
    PACKAGES_TO_INSTALL=()
    for i in "${PACKAGES[@]}"
    do
        echo -ne "INFO: Checking for ${i}"
        if [[ $(dpkg -l ${i} | grep -c ii) -gt 0 ]] > /dev/null 2>&1
        then
            echo ": Installed"
        else
            echo ": Missing"
            PACKAGES_TO_INSTALL+=("$i")
        fi
    done
    if [[ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]]
    then
        echo "INFO: Will install: ${PACKAGES_TO_INSTALL[@]}"

        run_privileged "update apt repositories" "apt-get" "update"
        if [[ $? -ne 0 ]]
        then
            return 1
        fi
        run_privileged "install prerequisites" "apt-get" "install" "-y" "${PACKAGES_TO_INSTALL[@]}"
        if [[ $? -ne 0 ]]
        then
            return 1
        fi
    fi
    return 0
}

read_boolean_answer() {
    while true; do
        echo -e "$1"
        if [ "x$AUTO_INSTALL" == "xy" ]; then
            echo "AUTO_INSTALL says yes"
            REPLY="y"
            break;
        else
            read -r -n 1
            echo # print empty line after input
            case $REPLY in
                [Yy]* ) REPLY="y"; break;;
                [Nn]* ) REPLY="n"; break;;
                * ) echo "Please answer yes or no.";;
            esac
        fi
    done
}

list_scripts() {
	local DIR=${1}

	echo "Listing available installation scripts:"
	for i in ${DIR}/*.sh; do
		if [ -x $i ]
		then
			SCRIPT=$(basename -s .sh ${i})
			echo -e "\t${SCRIPT}"
		fi
	done
	return 0
}

execute_script() {
    local SCRIPT=${1}
    local SCRIPT_PARAMS=${2}

    SCRIPT_BASENAME=$(basename -s .sh ${SCRIPT})
    echo "INFO:Executing script: ${SCRIPT_BASENAME}"
    if [[ ! -x ${SCRIPT} ]]
    then
        echo "ERROR: Script ${SCRIPT} is not found or not executable!"
        return 2
    else
        if [[ -z ${SCRIPT_PARAMS} ]]
        then
            "${SCRIPT}"
        else
            echo "INFO: using parameters: ${SCRIPT_PARAMS}"
            "${SCRIPT}" ${SCRIPT_PARAMS}
        fi
        EXIT_CODE="$?"
        if [[ ${EXIT_CODE} -ne 0 ]]
        then
            echo "ERROR: ${SCRIPT} Failed with exitcode ${EXIT_CODE}!"
            return ${EXIT_CODE}
        else
            echo "INFO: Script ${SCRIPT} was successfull"
            return 0
        fi
    fi
}
