#!/bin/bash

scriptsource="https://raw.githubusercontent.com/daemonchild/ccc-ctf-may23/main/setup-scripts"

export LANG=en_GB.utf8
export LANGUAGE=
export LC_CTYPE="en_GB.utf8"
export LC_NUMERIC="en_GB.utf8"
export LC_TIME="en_GB.utf8"
export LC_COLLATE="en_GB.utf8"
export LC_MONETARY="en_GB.utf8"
export LC_MESSAGES="en_GB.utf8"
export LC_PAPER="en_GB.utf8"
export LC_NAME="en_GB.utf8"
export LC_ADDRESS="en_GB.utf8"
export LC_TELEPHONE="en_GB.utf8"
export LC_MEASUREMENT="en_GB.utf8"
export LC_IDENTIFICATION="en_GB.utf8"
export LC_ALL=

echo "[Installing Full Kali]"
apt update
apt full-upgrade -y
apt install -y kali-linux-default

# SSH Config

wget -q -O - "${scriptsource}/kali/sshd_config.txt" > /etc/ssh/sshd_config
systemctl restart sshd

# Diable IPv6
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf

# Windows
echo "[Installing xfce and XRDP]"
apt-get -y install kali-defaults kali-root-login desktop-base xfce4 xfce4-places-plugin xfce4-goodies libu2f-udev
apt-get -y install xrdp

echo "port tcp://:3389" >> /etc/xrdp/xrdp.ini

systemctl enable xrdp
systemctl enable xrdp-sesman
systemctl start xrdp
systemctl start xrdp-sesman

#mkdir /home/student/.vnc
#echo "5tudent!" | vncpasswd -f > /home/student/.vnc/passwd
#chown -R student:student /home/student/.vnc
#chmod 0600 /home/student/.vnc/passwd

systemctl set-default graphical.target

# User experience

useradd -m student
echo 'student:5tudent!' | chpasswd

touch /home/student/.hushlogin 
touch /home/kaliadmin/.hushlogin

echo 'student ALL=(ALL) NOPASSWD:ALL' | EDITOR='tee -a' visudo
usermod -a -G sudo student
chsh student -s /bin/zsh


# install chrome, firefox, additional tools
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /root/google-chrome-stable_current_amd64.deb
apt-get -y install fonts-liberation desktop-file-utils mailcap man-db
dpkg -i /root/google-chrome-stable_current_amd64.deb
rm /root/google-chrome-stable_current_amd64.deb

# Stop that annoying popup!
wget -q -O - "${scriptsource}/kali/45-allow-colord.pkla" > /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla

# Customisation
wget -q -O - "${scriptsource}/kali/motd.txt" > /etc/motd
wget -q -O - "${scriptsource}/kali/cybercollege-admiral-wallpaper.jpg" > /etc/wallpaper.jpg
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitorrdp0/workspace0/last-image -s /etc/wallpaper.png

touch /home/kaliadmin/"___PLEASE LEAVE THIS FOLDER ALONE - REQUIRED FOR CTF STAFF SUPPORT___"

# clear up

for u in root kaliadmin student do {

   cat /dev/null > /home/$u/.bash_history;
   cat /dev/null > /home/$u/.zsh_history;
} done
   




