#!/bin/bash

sudo yum -y install git bzip2 perl-Switch perl-Env perl-Thread-Queue libXpm-devel libXext-devel mesa-libGLU-devel libXinerama libXi libXft-devel libXrandr libXcursor zsh tk perl-ExtUtils-Embed compat-libstdc++-33 libXmu
sudo firewall-cmd --zone=public --add-port=8070/tcp --permanent
sudo firewall-cmd --reload
sudo mkdir /dqm-gui
sudo chown tmudholk:zh /dqm-gui
