check_number_of_arguments() { # Syntax: check_number_of_arguments expected-number-of-arguments function_name whitespace-separated-list-of-arguments 
    if [ "$(($# - 2))" -ne  "$1" ]; then
        echo "$2: unexpected number of arguments, or unexpectedly empty arguments. Expected number of arguments: $1. Provided list of arguments: ${@:3}"
        exit
    fi
}

set_os_dependent_env_vars() {
    check_number_of_arguments 0 "set_os_dependent_env_vars" $@
    GUIPATH="/dqm-gui"
    BASEHOSTNAME=$(echo $HOSTNAME | sed "s|\([^\.]*\)\.cern\.ch|\1|")
    DEPLOYMENT_VERSION=""
    BASEDEPVERSION=$(cat /etc/redhat-release)

    possibly_slc6=$(echo "${BASEDEPVERSION}" | grep -e "^Scientific Linux CERN SLC release 6.*")
    possibly_cc7=$(echo ${BASEDEPVERSION} | grep -e "^CentOS Linux release 7.*")
    if [ -n "${possibly_slc6}" ]; then
        DEPLOYMENT_VERSION="slc6"
    elif [ -n "${possibly_cc7}" ]; then
        DEPLOYMENT_VERSION="cc7"
    else
        echo "Either OS info not found in /etc/redhat-release, or found info does not match SLC6 or CC7. BASEDEPVERSION = ${BASEDEPVERSION}"
        exit
    fi
    
    if [[ "$BASEHOSTNAME" =~ ^lxplus[0-9]{3,4}$ ]]; then
        GUIPATH="/tmp/tmudholk"
        DEPLOYMENT_VERSION="slc6" # yes, even for lxplus7
    fi
    
    echo "Setting GUIPATH to ${GUIPATH}, DEPLOYMENT_VERSION to ${DEPLOYMENT_VERSION}"
    export GUIPATH
    export DEPLOYMENT_VERSION
}

search_for_running_gui() {
    check_number_of_arguments 0 "check_for_running_gui" $@
    SEARCHFORRUNNINGGUI=$(ps aux | grep -v grep | grep "visDQMRender")
    echo ${SEARCHFORRUNNINGGUI}
}

update_dqm_gui_status() {
    DQM_GUI_STATUS=""
    SEARCHFORRUNNINGGUI=$(search_for_running_gui)
    if [ -z "${SEARCHFORRUNNINGGUI}" ]; then
        DQM_GUI_STATUS="down"
    else
        DQM_GUI_STATUS="up"
    fi
    echo "Updating DQM_GUI_STATUS to ${DQM_GUI_STATUS}"
    export DQM_GUI_STATUS
}

exit_if_gui_up() {
    update_dqm_gui_status
    if [ "${DQM_GUI_STATUS}" == "down" ]; then
        echo "DQM not currently running."
    else
        echo "DQM already running. Please check!"
        exit
    fi
}

exit_if_gui_down() {
    update_dqm_gui_status
    if [ "${DQM_GUI_STATUS}" == "down" ]; then
        echo "No DQM instance found running. Please check!"
        exit
    else
        echo "DQM instance found."
    fi
}

show_dqm_status() {
    update_dqm_gui_status
    if [ "${DQM_GUI_STATUS}" == "down" ]; then
        echo "No DQM instance found running!"
    else
        echo "DQM running."
    fi
}


check_optional_argument() { # Syntax: check_optional_argument name_of_argument current_value value_to_check
    if [ -z "$3" ]; then
        echo "Setting $1 to its default value: $2"
        echo $2
    else
        echo "Setting $1 to a non-default value: $3"
        echo $3
    fi
}

print_potential_error() { # Syntax: print_potential_error returnvalue error_message
    check_number_of_arguments 2 "print_potential_error" "$@"
    if [ $1 -ne 0 ]; then
        echo "$2"
        exit
    fi
}

set_latest_tag() {
    check_number_of_arguments 0 "get_latest_tag" $@
    echo "Fetching latest deployment tag..."
    LATESTTAG=`curl -s https://api.github.com/repos/dmwm/deployment/tags | grep name | grep -m 1 HG | grep -o -e HG[0-9][0-9][0-9][0-9][a-z]`
    if [ -z "${LATESTTAG}" ]; then
        echo "Latest release not found!"
        exit
    else
        echo "Latest release found: ${LATESTTAG}. Deploying with this version..."
    fi
    export LATESTTAG
}

dqm_deploy() {
    check_number_of_arguments 2 "dqm_deploy" $@
    echo "Deploying DQM..."
    if [ "${2}" == "slc6" ]; then
        $PWD/deployment/Deploy -A slc6_amd64_gcc493 -r "comp=comp" -R comp@${1} -t MYDEV -s "prep sw post" $PWD dqmgui/bare
    elif [ "${2}" == "cc7" ]; then
        $PWD/deployment/Deploy -A slc7_amd64_gcc630 -r "comp=comp" -R comp@${1} -t MYDEV -s "prep sw post" $PWD dqmgui/bare
    else
        echo "Unrecognized DEPLOYMENT_VERSION: ${2}"
    fi
    print_potential_error $? "Unable to (re-)deploy!"
}

source_env() {
    check_number_of_arguments 0 "source_env" $@
    echo "Sourcing env.sh..."
    source current/apps/dqmgui/128/etc/profile.d/env.sh
    print_potential_error $? "Unable to source env!"
}

start_chosen_flavor() {
    check_number_of_arguments 1 "start_chosen_flavor" $@
    echo "Starting server for flavor ${1}"
    $PWD/current/config/dqmgui/manage -f $1 start "I did read documentation"
    print_potential_error $? "Unable to start online DQM!"
}

stop_chosen_flavor() {
    check_number_of_arguments 1 "stop_chosen_flavor" $@
    echo "Stopping server for flavor ${1}"
    $PWD/current/config/dqmgui/manage -f $1 stop "I did read documentation"
    print_potential_error $? "Something went wrong in trying to stop the DQM instances... are you sure there were any?"
}

refresh_files() {
    check_number_of_arguments 1 "refresh_files" $@
    for fileToUpload in $(find $1 -maxdepth 1 -type f -name "DQM*.root"); do
        echo "Detected new file: ${fileToUpload}"
        if [ ${FLAVOR} == online ]; then
            visDQMIndex add --dataset /Global/Online/ALL state/dqmgui/online/ix128 ${fileToUpload}
        elif [ ${FLAVOR} == offline ]; then
            visDQMIndex add state/dqmgui/offline/ix128 ${fileToUpload}
        fi
        print_potential_error $? "Unable to upload ${fileToUpload} to DQM instance!"
        mkdir -p ${1}/closed
        print_potential_error $? "Unable to create directory: ${1}/closed. Please check permissions!"
        rsync -a -v -c ${fileToUpload} ${1}/closed/ && rm ${fileToUpload}
        print_potential_error $? "Unable to copy file to closed and remove it from source directory: ${fileToUpload}. Please check permissions!"
    done
}

check_user_OK() {
    echo "OK to proceed? (y/n): "
    read user_response
    parsed_user_response=$(echo ${user_response} | grep -e "^[yn]$")
    while [ -z "${parsed_user_response}" ]; do
        echo "Please enter y or n. OK to proceed? (y/n): "
        read user_response
        parsed_user_response=$(echo ${user_response} | grep -e "^[yn]$")
    done
    if [ ${user_response} == "y" ]; then
        echo "OK, proceeding!"
    else
        echo "Terminating..."
        exit
    fi
}
