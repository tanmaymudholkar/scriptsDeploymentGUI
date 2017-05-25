#!/bin/bash

PATHTODQMFILES=/afs/cern.ch/work/t/tmudholk/public/DQMUploads
FLAVOR=online

if [ -z "$1" ]; then
    echo "Using default path to DQM files: ${PATHTODQMFILES}"
else
    PATHTODQMFILES=$1
fi

cd /tmp/tmudholk/gui

echo "Sourcing env"
source current/apps/dqmgui/128/etc/profile.d/env.sh
if [ $? -ne 0 ]; then
    echo "Unable to source env.sh!"
    exit
fi

for fileToUpload in ${PATHTODQMFILES}/*; do
    echo "Detected: ${fileToUpload}"
    
    if [ ${FLAVOR} == online ]; then
        visDQMIndex add --dataset /Global/Online/ALL state/dqmgui/online/ix128 ${fileToUpload}
    elif [ ${FLAVOR} == offline ]; then
        visDQMIndex add state/dqmgui/offline/ix128 ${fileToUpload}
    fi
    if [ $? -ne 0 ]; then
        echo "Unable to copy files to online DQM!"
        exit
    fi
done
