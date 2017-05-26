#!/bin/bash

source defaults.sh
source commonFunctions.sh

set_os_dependent_env_vars
cd ${GUIPATH}/gui

show_dqm_status

update_dqm_gui_status

if [ ${DQM_GUI_STATUS} == "up" ]; then
    stop_chosen_flavor ${FLAVOR}
fi

rm -rf ${GUIPATH}/gui
