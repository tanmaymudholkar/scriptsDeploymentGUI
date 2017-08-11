#!/bin/bash

source commonFunctions.sh

set_os_dependent_env_vars
cd ${GUIPATH}
source_host_specific_config

cd gui
show_dqm_status

update_dqm_gui_status

if [ ${DQM_GUI_STATUS} == "up" ]; then
    stop_chosen_flavor ${FLAVOR}
fi

cd && rm -rf ${GUIPATH}/gui
