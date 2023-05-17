~/!bin/bash

export scriptsource="https://raw.githubusercontent.com/daemonchild/ccc-ctf-may23/main/setup-scripts"

apt-get -y update
apt-get -y upgrade
apt-get -y install docker.io docker-compose

docker pull guacamole/guacd
docker pull guacamole/guacamole
docker pull nginx:latest

docker run --name guacd-151 -d guacamole/guacd

docker run -d --name guacamole-151 -p 80:8080 --link guacd-151:guacd \
	-e MYSQL_HOSTNAME=mysqlsvr.mysql.database.azure.com \
	-e MYSQL_PORT=3306 \
	-e MYSQL_DATABASE=guacamoledb \
	-e MYSQL_USER=mysqladmin@mysqlsvr \
	-e MYSQL_PASSWORD=mysqlpassword \
	-e MYSQL_SSL_MODE=disabled \
	guacamole/guacamole

#wget -q "${scriptsource}/guacamole/nginx-site.conf" -O /root/nginx-site.conf

#docker run -d --name nginx-proxy -p 80:80 --link guacamole-151 nginx

#wget -q "${scriptsource}/guacamole/nginx-site.conf" -O /etc/nginx/sites-enabled/default