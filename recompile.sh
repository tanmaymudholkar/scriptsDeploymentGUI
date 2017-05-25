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
    if [ $? -ne 0 ]; then
        echo "Unable to check out new version of ${CURRENTBRANCHNAME}!"
    fi
fi
cd ..
LATESTTAG=`curl -s https://api.github.com/repos/dmwm/deployment/tags | grep name | grep -m 1 HG | grep -o -e HG[0-9][0-9][0-9][0-9][a-z]`
if [ -z "${LATESTTAG}" ]; then
    echo "Latest release not found!"
    exit
else
    echo "Latest release found: ${LATESTTAG}. (Re-)deploying..."
fi

$PWD/deployment/Deploy -A slc6_amd64_gcc493 -r "comp=comp" -R comp@${LATESTTAG} -t MYDEV -s "prep sw post" $PWD dqmgui/bare
if [ $? -ne 0 ]; then
    echo "Unable to (re-)deploy!"
    exit
fi

$PWD/current/config/dqmgui/manage -f ${FLAVOR} start "I did read documentation"
if [ $? -ne 0 ]; then
    echo "Unable to start online DQM!"
    exit
fi

cd ${CURRENTWORKDIR}
