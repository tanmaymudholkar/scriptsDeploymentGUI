#!/bin/bash

FLAVOR=online
CURRENTWORKDIR=`pwd`

cd /tmp/tmudholk/gui
SEARCHFORRUNNINGGUI=`ps aux | grep -v grep | grep visDQMRender`
if [ -z "${SEARCHFORRUNNINGGUI}" ]; then
    echo "No DQM process found running!"
else
    echo "Stopping DQM processes..."
fi

$PWD/current/config/dqmgui/manage -f ${FLAVOR} stop "I did read documentation"
if [ $? -ne 0 ]; then
    echo "Something went wrong in trying to stop the DQM instances... are you sure there were any?"
fi

rm -rf /tmp/tmudholk/gui

cd ${CURRENTWORKDIR}
