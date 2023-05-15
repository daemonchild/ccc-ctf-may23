#!/bin/bash

apt-get -y update
apt-get -y upgrade
apt-get -y install docker.io docker-compose

scriptsource="https://raw.githubusercontent.com/daemonchild/ccc-ctf-may23/main/setup-scripts"

wget -q "${scriptsource}/ctfd/ctf351fork.tgz" -O /root/ctfd351fork.tgz
tar -zxf /root/ctfd351fork.tgz
cd ctfd351fork

docker-compose build
docker-compose up -d

wget -q "${scriptsource}/ctfd/uploads.tgz" -O /root/uploads.tgz


