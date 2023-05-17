~/!bin/bash

apt-get -y update
apt-get -y upgrade
apt-get -y install docker.io docker-compose

docker pull guacamole/guacd
docker pull guacamole/guacamole
docker pull nginx:latest

docker run --name guacd-151 -d guacamole/guacd

docker run -d --name guacamole-151 --link guacd-151:guacd \
	-e MYSQL_HOSTNAME=mysql-ccc-ctf-may23.mysql.database.azure.com \
	-e MYSQL_PORT=3306 \
	-e MYSQL_DATABASE=guacamoledb \
	-e MYSQL_USER=guacdbuser@mysql-ccc-ctf-may23 \
	-e MYSQL_PASSWORD=tNTUwfshM93P1w66_1jalkDDZSgYe5S9ySVT6D_mu \
	-e MYSQL_SSL_MODE=disabled \
	guacamole/guacamole

docker run -d --name nginx-proxy -p 80:80 --link guaqamole-151 guacamole