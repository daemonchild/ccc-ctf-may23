# 
#                      _    __                           ____   ___ ____  _____ 
#   ___ ___ ___    ___| |_ / _|  _ __ ___   __ _ _   _  |___ \ / _ \___ \|___ / 
#  / __/ __/ __|  / __| __| |_  | '_ ` _ \ / _` | | | |   __) | | | |__) | |_ \ 
# | (_| (_| (__  | (__| |_|  _| | | | | | | (_| | |_| |  / __/| |_| / __/ ___) |
#  \___\___\___|  \___|\__|_|   |_| |_| |_|\__,_|\__, | |_____|\___/_____|____/ 
#                                                |___/                          
#


# Util Functions
randpassword () {

    < /dev/urandom tr -dc _A-Z-a-z-0-9[!=-_+^%] | head -c${1:-40}

}

# Variables
setvars () {

    echo "[Setting Variables]"

    # Global to Deployment
    export project="ccc-ctf-may23"
    export location="uksouth"
    export resgrp="rg-${project}"
    export domainname="cybercollege.cymru"
    export guacdnsname="login"
    export ctfddnsname="scores"

    export scriptsource="https://raw.githubusercontent.com/daemonchild/ccc-ctf-may23/main/setup-scripts"

    # Vnet
    export vnet="vnet-${project}"                          
    export twooctets="10.250"
    export ipsubnet="${twooctets}.0.0/16"

    export utilsubnet="${twooctets}.240.0/24"
    export guacsubnet="${twooctets}.250.0/24"
    export ctfdsubnet="${twooctets}.251.0/24"
    export appgwsubnet="${twooctets}.252.0/24"

    export utilsubnetname="subnetUtility"
    export guacsubnetname="subnetGuacamole"
    export ctfdsubnetname="subnetCTFd"
    export appgwsubnetname="subnetAppGw"

    export challengenetprefix="subnetTeam"

    # AppGw

    export appgwname="appGW-${project}"
    export appgwpipname="pip-${appgwname}"
    
    export appgwpoolguacname="${project}-pool-guacamole"
    export appgwguacfqdn="${guacdnsname}.${domainname}"
    export appgwguacrulename="${project}-routingrule-guacamole"
    export appgwguaclistenername="${project}-listener-guacamole"
    export appgwguacbename="${project}-backend-guacamole"
    export appgwguacprobename="${project}-probe-guacamole"

    export appgwpoolctfdname="${project}-pool-ctfd"
    export appgwctfdfqdn="${ctfddnsname}.${domainname}"
    export appgwctfdrulename="${project}-routingrule-ctfd"
    export appgwctfdlistenername="${project}-listener-ctfd"
    export appgwctfdbename="${project}-backend-ctfd"
    export appgwctfdprobename="${project}-probe-ctfd"
    

    # VMs Common

    export ctfadmin="ctfadmin"
    export kaliadmin="kaliadmin"

    export linuximage="Canonical:UbuntuServer:18.04-LTS:latest"
    export kaliimage="kali-linux:kali:kali-20231:2023.1.0"

    export linuxsku="Standard_D2s_v3"
    export kalisku="Standard_D2s_v3"
    export dockersku="Standard_D2s_v3"
    export guacsku="Standard_D2_v3"
    export ctfdsku="Standard_D2_v3"

    export vmprefix="vm"

    # Static IP (last octet)
    export kalistatic="200"
    export dockerstatic="50"
    export windows1static="31"
    export windows2static="32"

    # Build Values

    export guacscale=1
    export ctfdscale=1
    export challenge=1

    # MySQL Database

    export mysqlsku=B_Gen5_1
    export mysqlsvr="mysql-${project}"
    export mysqlsvrurl="${mysqlsvr}.mysql.database.azure.com"
    export mysqladmin="${ctfadmin}"

    export guacmysqluser="guacdbuser"
    export ctfdmysqluser="ctfddbuser"
    export guacdb="guacamoledb"
    export ctfddb="ctfd"

}

buildall () {

    setvars
    buildrg
    buildnets
    buildfirewalls

}

buildrg () {

    echo "[Creating Resource Group]"
    az group create --name $resgrp --location $location

}

buildnets () {

    echo "[Building Infrastructure Networking]"

    az network vnet create \
    --resource-group $resgrp \
    --name $vnet \
    --address-prefix $ipsubnet 

    az network vnet subnet create --name $utilsubnetname --vnet-name $vnet --resource-group $resgrp --address-prefixes $utilsubnet
    az network vnet subnet create --name $guacsubnetname --vnet-name $vnet --resource-group $resgrp --address-prefixes $guacsubnet
    az network vnet subnet create --name $ctfdsubnetname --vnet-name $vnet --resource-group $resgrp --address-prefixes $ctfdsubnet
    az network vnet subnet create --name $appgwsubnetname --vnet-name $vnet --resource-group $resgrp --address-prefixes $appgwsubnet

}

buildmysql () {

    echo "Building MySQL Server"

    export mysqlpassword=`randpassword`
    echo "admin: ${mysqladmin}:${mysqlpassword}" >> ./warning-saved-creds.txt

    export guacmysqlpassword=`randpassword`
    echo "guac: ${guacmysqluser}:${guacmysqlpassword}" >> ./warning-saved-creds.txt

    export guacmysqlpassword=`randpassword`
    echo "ctfd: ${ctfdmysqluser}:${guacmysqlpassword}" >> ./warning-saved-creds.txt


    az mysql server create \
    --resource-group $resgrp \
    --name $mysqlsvr \
    --location $location \
    --admin-user $mysqladmin \
    --admin-password $mysqlpassword \
    --sku-name $mysqlsku \
    --storage-size 51200 \
    --ssl-enforcement Disabled

    az mysql server firewall-rule create \
    --resource-group $resgrp \
    --server $mysqlsvr \
    --name AllowAllForBuild \
    --start-ip-address 0.0.0.0 \
    --end-ip-address 255.255.255.255

    echo "[**** Make note! MySQL database creds saved in 'warning-saved-creds.txt' ****]"
    tail -n 3 ./warning-saved-creds.txt

}

buildfirewalls () {

    echo "Building Firewalls and Rules"

    # Network Security Groups
    az network nsg create --resource-group $resgrp --name "nsg-${utilsubnetname}"
    az network nsg create --resource-group $resgrp --name "nsg-${guacsubnetname}"
    az network nsg create --resource-group $resgrp --name "nsg-${ctfdsubnetname}"
    az network nsg create --resource-group $resgrp --name "nsg-${appgwsubnetname}"

    az network nsg create --resource-group $resgrp --name "nsg-${appgwsubnetname}"

    # Rules

    # Utility Network
    az network nsg rule create \
        --resource-group $resgrp \
        --nsg-name "nsg-${utilsubnetname}" \
        --name AllowSSHfromInternet \
        --access Allow \
        --protocol Tcp \
        --direction Inbound \
        --priority 100 \
        --source-address-prefix Internet \
        --source-port-range "*" \
        --destination-address-prefix "*" \
        --destination-port-range 22

    az network nsg rule create \
        --resource-group $resgrp \
        --nsg-name "nsg-${utilsubnetname}" \
        --name AllowHTTPfromInternet \
        --access Allow \
        --protocol Tcp \
        --direction Inbound \
        --priority 110 \
        --source-address-prefix Internet \
        --source-port-range "*" \
        --destination-address-prefix "*" \
        --destination-port-range 80

    az network nsg rule create \
        --resource-group $resgrp \
        --nsg-name "nsg-${utilsubnetname}" \
        --name AllowHTTPSfromInternet \
        --access Allow \
        --protocol Tcp \
        --direction Inbound \
        --priority 120 \
        --source-address-prefix Internet \
        --source-port-range "*" \
        --destination-address-prefix "*" \
        --destination-port-range 443

    # Guacamole Network

    az network nsg rule create \
        --resource-group $resgrp \
        --nsg-name "nsg-${guacsubnetname}" \
        --name AllowHTTP \
        --access Allow \
        --protocol Tcp \
        --direction Inbound \
        --priority 100 \
        --source-address-prefix Internet \
        --source-port-range "*" \
        --destination-address-prefix "*" \
        --destination-port-range 80

    az network nsg rule create \
        --resource-group $resgrp \
        --nsg-name "nsg-${guacsubnetname}" \
        --name AllowAppGWPorts \
        --access Allow \
        --protocol Tcp \
        --direction Inbound \
        --priority 110 \
        --source-address-prefix "*" \
        --source-port-range "*" \
        --destination-address-prefix "*" \
        --destination-port-range "65200-65535"

    az network nsg rule create \
        --resource-group $resgrp \
        --nsg-name "nsg-${guacsubnetname}" \
        --name AllowRDP \
        --access Allow \
        --protocol Tcp \
        --direction Outbound \
        --priority 120 \
        --source-address-prefix "*" \
        --source-port-range "*" \
        --destination-address-prefix "${twooctets}" \
        --destination-port-range 3389

    # max 63 teams
    az network nsg rule create \
        --resource-group $resgrp \
        --nsg-name "nsg-${guacsubnetname}" \
        --name AllowRDPtoKali \
        --access Allow \
        --protocol Tcp \
        --direction Outbound \
        --priority 110 \
        --source-address-prefix "${guacsubnet}" \
        --source-port-range "*" \
        --destination-address-prefix "${twooctets}.0.0/18" \ 
        --destination-port-range 3389

    # not working below here... chekc outbound rules

    az network nsg rule create \
        --resource-group $resgrp \
        --nsg-name "nsg-${guacsubnetname}" \
        --name AllowSSHtoKali \
        --access Allow \
        --protocol Tcp \
        --direction Outbound \
        --priority 120 \
        --source-address-prefix "${guacsubnet}" \
        --source-port-range "*" \
        --destination-address-prefix "${twooctets}.0.0/18" \        
        --destination-port-range 22

    az network nsg rule create \
        --resource-group $resgrp \
        --nsg-name "nsg-${guacsubnetname}" \
        --name AllowMySQL \
        --access Allow \
        --protocol Tcp \
        --direction Outbound \
        --priority 130 \
        --source-address-prefix  "${guacsubnet}" \
        --source-port-range "*" \
        --destination-address-prefix "*" \        
        --destination-port-range 3306

}

buildutilsvr () {

    # The util server has certbot tools and ssh private keys

    local vmname="${vmprefix}-UtilServer"

    az vm create --name $vmname \
    --resource-group $resgrp \
    --size $linuxsku \
    --image $linuximage \
    --admin-username $ctfadmin \
    --generate-ssh-keys \
    --public-ip-address "pip-${vmname}" \
    --vnet-name $vnet \
    --subnet $utilsubnetname \
    --nsg "nsg-${utilsubnetname}" 

    # Deploy setup script

    az vm run-command invoke -g $resgrp -n $vmname  \
        --command-id RunShellScript \
        --scripts "wget -q -O - ${scriptsource}/utilsvr/setup.sh | bash" 

}

buildctfdsvr () {

    # CTFd Server for Scoreboard and Flags
    # Send this id to create

    local id=$1
    local vmname="${vmprefix}-CTFd-${id}"

    az vm create --name $vmname \
    --resource-group $resgrp \
    --size $ctfdsku \
    --image $linuximage \
    --admin-username $ctfadmin \
    --generate-ssh-keys \
    --public-ip-address "" \
    --vnet-name $vnet \
    --subnet $ctfdsubnetname \
    --nsg "nsg-${ctfdsubnetname}"

    # Deploy setup script

    az vm run-command invoke -g $resgrp -n $vmname  \
        --command-id RunShellScript \
        --scripts "wget -q -O - ${scriptsource}/ctfd/setup.sh | bash" 

    # modify
    #      - UPLOAD_FOLDER=/var/uploads
    #  - DATABASE_HOST=ctf-may23-guacamole.mysql.database.azure.com
    #  - DATABASE_PROTOCOL=mysql+pymysql
    #  - DATABASE_PORT=3306
    #  - DATABASE_USER=guacamoleuser@ctf-may23-guacamole
    #  - DATABASE_PASSWORD=1Promise2ChangeThisInProduction
    #  - DATABASE_NAME=ctfd


    # Add to AppGw





}


buildguacamole () {

   # Apache Guacamole Server - connection to Kali and Challenge networks
    # Send this id to create

    local id=$1
    local vmname="${vmprefix}-Guacamole-${id}"

    echo $vmname

    az vm create --name $vmname \
    --resource-group $resgrp \
    --size $guacsku \
    --image $linuximage \
    --admin-username $ctfadmin \
    --generate-ssh-keys \
    --public-ip-address "" \
    --vnet-name $vnet \
    --subnet $guacsubnetname \
    --nsg "nsg-${guacsubnetname}"
    #--no-wait \

    # Deploy setup script

    az vm run-command invoke -g $resgrp -n $vmname  \
        --command-id RunShellScript \
        --scripts "wget ${scriptsource}/guacamole/setup.sh -O /tmp/guac-setup.sh" 

    # Make changes to installer script for mysql details
    az vm run-command invoke -g $resgrp -n $vmname   \
    --command-id RunShellScript \
    --scripts "sudo sed -i.bkp -e 's/mysqlpassword/$mysqlpassword/g' \
    -e 's/mysqldb/$guacdb/g' \
    -e 's/mysqlsvr/$mysqlsvr/g' \
    -e 's/mysqladmin/$mysqladmin/g' /tmp/guac-setup.sh"

    az vm run-command invoke -g $resgrp -n $vmname  \
    --command-id RunShellScript \
    --scripts "/bin/bash /tmp/guac-setup.sh"

}



builddockersvr () {

    # Docker Server used to host challenges

    local team=$1
    local vmname="${vmprefix}-Dockerhost-${team}"
    local staticip="${twooctets}.${team}.${dockerstatic}"
    local subnetname="${challengenetprefix}-${team}"

    az network nsg create --resource-group $resgrp --name "nsg-${vmname}"

    az vm create --name $vmname \
    --resource-group $resgrp \
    --size $dockersku \
    --image $linuximage \
    --admin-username $ctfadmin \
    --generate-ssh-keys \
    --public-ip-address "" \
    --vnet-name $vnet \
    --subnet $subnetname \
    --nsg "nsg-${vmname}" 
    #--no-wait \

    # Deploy setup script

    az vm run-command invoke -g $resgrp -n $vmname  \
        --command-id RunShellScript \
        --scripts "wget -q -O - ${scriptsource}/docker/setup.sh | bash" 

    # add Rules to firewall



}


buildchallengenet () {

    # Supply team number

    local team=$1
    local subnetname="${challengenetprefix}-${team}"
    local subnet="${twooctets}.${team}.0/24"
    az network vnet subnet create --name $subnetname --vnet-name $vnet --resource-group $resgrp --address-prefixes $subnet

}


buildkali () {

   # Student Kali Box

    local team=$1
    local vmname="${vmprefix}-Kali-${team}"

    echo "[Building Kali ${vmname}]"

    local subnetname="${challengenetprefix}-${team}"
    local subnet="${twooctets}.${team}.0/24"
    local staticip="${twooctets}.${team}.${kalistatic}"

    dockerhostname="${vmprefix}-host-team${i}"
    kalihostname="${vmprefix}-kali-team${i}"

    dockerstatic="${snetprefix}.50"
    kalistatic="${snetprefix}.200"

    az vm create --name $vmname \
    --resource-group $resgrp \
    --size $kalisku \
    --image $kaliimage \
    --admin-username $kaliadmin \
    --generate-ssh-keys \
    --public-ip-address "" \
    --vnet-name $vnet \
    --subnet $subnetname \
    --nsg "nsg-${vmname}" 
    #--no-wait \

    az network nic ip-config create --resource-group $resgrp --name "ipconfig-${vmname}" --nic-name "${vmname}VMNic"
    az network nic ip-config update --resource-group $resgrp --nic-name "${vmname}VMNic" --name "ipconfig-${vmname}" --private-ip-address $staticip



    # Deploy setup script

    az vm run-command invoke -g $resgrp -n $vmname  \
        --command-id RunShellScript \
        --scripts "wget -O ${scriptsource}/kali/setup.sh -O | bash" 

 
    # add Rules to firewall


}


