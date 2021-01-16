#!/bin/bash

PASS="Qaisbest!"

# System update
echo "##### System Update #####"
apt update
apt upgrade -y

# GUI setup
echo "##### Installing GUI #####"
apt -y install gnome-tweak-tool ubuntu-desktop gnome-panel gnome-settings-daemon metacity nautilus gnome-terminal gnome-software git apt-transport-https
systemctl set-default graphical.target
timedatectl set-timezone Europe/Bucharest

# QA user
echo "##### Set QA User #####"
useradd -m -s /bin/bash -p $(openssl passwd -crypt $PASS) qa
usermod -a -G sudo qa

# SSH setup
mkdir -p /home/qa/.ssh
mv /tmp/authorized_keys /home/qa/.ssh/authorized_keys
chown -R qa:qa /home/qa/.ssh
chmod 700 /home/qa/.ssh
chmod 600 /home/qa/.ssh/authorized_keys

# VNC setup
echo "##### Install VNC #####"
apt install -y tigervnc-standalone-server tigervnc-xorg-extension
mkdir -p /home/qa/.vnc
chown -R qa:qa /home/qa/.vnc
vncpasswd -f <<< $PASS > "/home/qa/.vnc/passwd"
chmod 0600 /home/qa/.vnc/passwd
mv /tmp/xstartup /home/qa/.vnc/xstartup
chmod +x /home/qa/.vnc/xstartup
chown -R qa:qa /home/qa/.vnc

# Java + JMeter
echo "##### Install Java + JMeter #####"
wget -O- https://apt.corretto.aws/corretto.key | sudo apt-key add -
add-apt-repository 'deb https://apt.corretto.aws stable main'
apt update
apt install -y java-1.8.0-amazon-corretto-jdk
wget https://mirrors.hostingromania.ro/apache.org/jmeter/binaries/apache-jmeter-5.4.zip -P /home/qa/
unzip /home/qa/apache-jmeter-5.4.zip -d /home/qa
chown -R qa:qa /home/qa/apache*

# VSCode
echo "##### VSCode #####"
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
apt update
apt install -y code

# Cleanup
echo "##### Cleanup #####"
apt remove -y thunderbird gnome-characters transmission-gtk transmission-common

# vncserver -kill :1
# vncserver -localhost no :1