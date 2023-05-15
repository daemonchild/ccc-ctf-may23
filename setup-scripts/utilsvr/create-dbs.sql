# Set up the mysql databases

CREATE DATABASE IF NOT EXISTS ctfd;
CREATE DATABASE IF NOT EXISTS guacamoledb;

CREATE USER IF NOT EXISTS 'guacdbuser' IDENTIFIED BY 'guacdbpassword';
CREATE USER IF NOT EXISTS 'ctfddbuser' IDENTIFIED BY 'ctfddbpassword';

GRANT ALL PRIVILEGES ON ctfd.* TO 'ctfddbuser'@'%';
GRANT ALL PRIVILEGES ON guacamoledb.* TO 'guacdbuser'@'%';

FLUSH PRIVILEGES;

