#!/bin/bash

source commonFunctions.sh

set_os_dependent_env_vars
cd ${GUIPATH}
source_host_specific_config

cd gui
show_dqm_status

update_dqm_gui_status
if [ "${DQM_GUI_STATUS}" == "up" ]; then
    stop_chosen_flavor ${FLAVOR}
fi

cd deployment
CURRENTBRANCHNAME=`git rev-parse --abbrev-ref HEAD`
if [ -z "${CURRENTBRANCHNAME}" ]; then
    echo "Unable to get current branch name!"
    exit
fi
if [ "${CURRENTBRANCHNAME}" == "master" ]; then
    echo "On master branch; no need to re-fetch"
else
    git checkout master && git branch -D ${CURRENTBRANCHNAME} && git fetch my-deployment && git checkout -b ${CURRENTBRANCHNAME} my-deployment/${CURRENTBRANCHNAME}
    print_potential_error $? "Unable to check out new version of ${CURRENTBRANCHNAME}!"
fi
cd ..

set_latest_tag

dqm_deploy ${LATESTTAG} ${DEPLOYMENT_VERSION}

start_chosen_flavor ${FLAVOR}
