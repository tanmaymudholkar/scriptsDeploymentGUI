#!/bin/bash

source defaults.sh
source commonFunctions.sh

set_os_dependent_env_vars
cd ${GUIPATH}/gui

source_env

refresh_files ${PATHTODQMFILES}
