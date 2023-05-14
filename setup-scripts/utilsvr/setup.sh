#!/bin/bash

apt-get -y update
apt-get -y upgrade

apt-get install -y docker.io mysql-client

docker pull certbot/certbot:latest
docker pull nginx:latest



