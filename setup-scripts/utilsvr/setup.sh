#!/bin/bash

apt-get -y update
apt-get -y upgrade

apt-get install -y docker.io mysql-client

docker pull certbot/certbot:latest
docker pull nginx:latest

# grab ssh keys
su - ctfadmin -c "ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa_local <<<y >/dev/null 2>&1"
su - ctfadmin -c "wget -q -O - https://github.com/console.keys >> ~/.ssh/authorized_keys"
su - ctfadmin -c "echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCoIefMlG8hxxyAMfC1uCpvgM4PYSYs+kBonHmZJENQRamNT1PlzTxhyXU5Ms+lVvLAuzI5FsAE3xPFmCyEMpsA+L5SZ7AzGlfhLyokh10M6PuGsTDmPfdi2kFDjfI/l65Gu+a4PrF3uSI1WAmazKkgN075+TYU6ldrWFrPYjPZEy5aK+zVrSsti5j+MYCfj4hxNaM5EmYMsLKKECtoUe/gWp3VSKKuKvrMvShTvjyYzlc1cayWXCz2d4Sd0/xpdIkK2OIoYrarULZo4LQYB4kxHYi+VZN+nbpkgam69e+YHSJycnTf/pTsiISyLvEaK8aw9q09y0rQP+jBK52HE+lCyGDJR+NuTCf7u2QTD/EC1dbAOyKl63ifu0ytlXMyjonDX1yYoJB+Fxaj8cNM1uKWRtR8zEx8445gMQP00YnvS+UiWmGpfzwkQG40vzHV/hgpPIPgoxTlKttP/NwlHLPZLEGa5kbpXcBDRJOKJZNwxxu3FhHCAIO7OF4eUyC2aXs= tomrowan@starbug' >> ~/.ssh/authorized_keys"

# Plague Runner
docker pull selenium/standalone-chrome
docker run -d -p 4444:4444 -v /dev/shm:/dev/shm selenium/standalone-chrome
wget https://raw.githubusercontent.com/Console/console.github.io/main/plague_runner.py -O /home/rich/plague_runner.py

