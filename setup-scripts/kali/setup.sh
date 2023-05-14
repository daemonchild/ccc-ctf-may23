#!/bin/bash

apt update
apt full-upgrade -y
apt install -y kali-linux-default

# SSH Config

echo "PubkeyAcceptedAlgorithms=+ssh-rsa" >> /etc/ssh/sshd_config
echo "HostKeyAlgorithms +ssh-rsa" >> /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart sshd

# Windows
apt-get -y install kali-defaults kali-root-login desktop-base xfce4 xfce4-places-plugin xfce4-goodies libu2f-udev
apt-get -y install xrdp
systemctl enable xrdp
systemctl enable xrdp-sesman

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
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/google-chrome-stable_current_amd64.deb
apt-get -y install fonts-liberation desktop-file-utils mailcap man-db
dpkg -i /tmp/google-chrome-stable_current_amd64.deb


cat <<EOF > /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla
polkit.addRule(function(action, subject) {
   if ((action.id == "org.freedesktop.color-manager.create-device" ||
        action.id == "org.freedesktop.color-manager.create-profile" ||
        action.id == "org.freedesktop.color-manager.delete-device" ||
        action.id == "org.freedesktop.color-manager.delete-profile" ||
        action.id == "org.freedesktop.color-manager.modify-device" ||
        action.id == "org.freedesktop.color-manager.modify-profile") &&
       subject.isInGroup("sudo")) {
      return polkit.Result.YES;
   }
});
EOF


