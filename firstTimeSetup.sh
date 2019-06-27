#!/bin/bash

echo "Performing first time setup..."
echo "Installing packages..."
sudo yum -y install git bzip2 perl-Switch perl-Env perl-Thread-Queue libXpm-devel libXext-devel mesa-libGLU-devel libXinerama libXi libXft-devel libXrandr libXcursor zsh tk perl-ExtUtils-Embed compat-libstdc++-33 libXmu
echo "Installed. Opening ports 9190, 8070, 8080, and 8081..."
sudo firewall-cmd --zone=public --add-port=9190/tcp --permanent
echo "...Opened 9190..."
sudo firewall-cmd --zone=public --add-port=8070/tcp --permanent
echo "...Opened 8070..."
sudo firewall-cmd --zone=public --add-port=8080/tcp --permanent
echo "...Opened 8080..."
sudo firewall-cmd --zone=public --add-port=8081/tcp --permanent
echo "...Opened 8081. Now enabling masquerade..."
sudo firewall-cmd --zone=public --add-masquerade
echo "Masquerade enabled. Warning: maybe I am being dense, but this appears to take time to take effect. Now autoforwarding port 80 to 8070..."
sudo firewall-cmd --zone=public --add-forward-port=port=80:proto=tcp:toport=8070 --permanent
echo "Autoforwarding set. Now reloading firewalld..."
sudo firewall-cmd --reload
echo "Reloaded firewalld. Now creating /dqm-gui and changing permissions..."
sudo mkdir /dqm-gui
sudo chown tmudholk:zh /dqm-gui
echo "All done!"
