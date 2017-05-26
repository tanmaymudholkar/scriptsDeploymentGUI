#!/bin/bash

source defaults.sh
source commonFunctions.sh

echo "Please check these settings for the online DQM:" && cat defaults.sh && check_user_OK

set_os_dependent_env_vars

exit_if_gui_up

cd ${GUIPATH} && mkdir -p gui && cd gui
print_potential_error $? "Something went wrong in creating ${GUIPATH}/gui, please check"

git clone git@github.com:dmwm/deployment
print_potential_error $? "Something went wrong in cloning from git repo, please check"

if [ "${GITHUB_BRANCH}" == "master" ]; then
    echo "using master branch"
else
    cd deployment
    git remote add my-deployment git@github.com:tanmaymudholkar/deployment
    git fetch my-deployment
    print_potential_error $? "Unable to fetch deployment repo from tmudholk"

    git checkout -b ${GITHUB_BRANCH} my-deployment/${GITHUB_BRANCH}
    print_potential_error $? "Unable to checkout given branch: ${GITHUB_BRANCH}"
    cd ..
fi

set_latest_tag # sets LATESTTAG

dqm_deploy ${LATESTTAG} ${DEPLOYMENT_VERSION}

source_env

start_chosen_flavor ${FLAVOR}

refresh_files ${PATHTODQMFILES}
