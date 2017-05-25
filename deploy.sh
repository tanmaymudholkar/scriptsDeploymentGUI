#!/bin/bash

PATHTODQMFILES=/afs/cern.ch/work/t/tmudholk/public/DQMUploads
FLAVOR=online
CURRENTWORKDIR=`pwd`

if [ -z "$1" ]; then
    echo "Please enter name of github branch, or explicitly specify master"
    exit
fi

if [ -z "$2" ]; then
    echo "Using default path to DQM files: ${PATHTODQMFILES}"
else
    PATHTODQMFILES=$2
fi

SEARCHFORRUNNINGGUI=`ps aux | grep -v grep | grep visDQMRender`
if [ -z "${SEARCHFORRUNNINGGUI}" ]; then
    echo "DQM not currently running. Starting..."
else
    echo "DQM already running. Quitting!"
    exit
fi

cd /tmp/tmudholk && mkdir -p gui && cd gui
if [ $? -ne 0 ]; then
    echo "Something went wrong in creating /tmp/tmudholk/gui, please check"
    exit
fi

git clone git@github.com:dmwm/deployment
if [ $? -ne 0 ]; then
    echo "Something went wrong in cloning from git repo, please check"
    exit
fi

if [ "$1" == "master" ]; then
    echo "using master branch"
else
    cd deployment
    git remote add my-deployment git@github.com:tanmaymudholkar/deployment
    git fetch my-deployment
    if [ $? -ne 0 ]; then
        echo "Unable to fetch deployment repo from tmudholk"
        exit
    fi

    git checkout -b $1 my-deployment/$1
    if [ $? -ne 0 ]; then
        echo "Unable to checkout given branch: $1"
        exit
    fi
    cd ..
fi

LATESTTAG=`curl -s https://api.github.com/repos/dmwm/deployment/tags | grep name | grep -m 1 HG | grep -o -e HG[0-9][0-9][0-9][0-9][a-z]`
if [ -z "${LATESTTAG}" ]; then
    echo "Latest release not found!"
    exit
else
    echo "Latest release found: ${LATESTTAG}. Deploying..."
fi

$PWD/deployment/Deploy -A slc6_amd64_gcc493 -r "comp=comp" -R comp@${LATESTTAG} -t MYDEV -s "prep sw post" $PWD dqmgui/bare
if [ $? -ne 0 ]; then
    echo "Unable to deploy!"
    exit
fi

echo "Sourcing env"
source current/apps/dqmgui/128/etc/profile.d/env.sh
if [ $? -ne 0 ]; then
    echo "Unable to source env.sh!"
    exit
fi

$PWD/current/config/dqmgui/manage -f ${FLAVOR} start "I did read documentation"
if [ $? -ne 0 ]; then
    echo "Unable to start online DQM!"
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

cd ${CURRENTWORKDIR}
