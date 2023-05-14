#!/bin/bash

apt-get -y update
apt-get -y upgrade
apt-get -y install docker.io

docker pull ubuntu:latest
docker pull mattrayner/lamp:latest

# Test container deployment
git clone https://github.com/daemonchild/file-generator.git
cd file-generator
docker build -t filegen:0.3 .
docker run --restart always -d -p 9000:9000 --name api-filegen filegen:0.3

# Move ssh to another port
echo Port 6222 >> /etc/ssh/sshd_config
systemctl restart sshd

