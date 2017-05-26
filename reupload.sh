#!/bin/bash

source defaults.sh
source commonFunctions.sh

set_guipath
cd ${GUIPATH}/gui

source_env

refresh_files ${PATHTODQMFILES}
