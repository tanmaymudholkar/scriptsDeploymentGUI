#!/bin/bash

source commonFunctions.sh

set_os_dependent_env_vars
cd ${GUIPATH}
source_host_specific_config

cd gui
source_env

refresh_files ${PATHTODQMFILES}
