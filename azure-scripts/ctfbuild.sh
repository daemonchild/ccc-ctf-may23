#
#
#
#
#
#
#

# Variables

randpassword () {

    < /dev/urandom tr -dc _A-Z-a-z-0-9[!=-_+^%] | head -c${1:-40}

}

setvars () {

    echo "[Setting Variables]"

    # Global to Deployment
    project="ctf-may23"
    location="uksouth"
    resgrp="rg-${project}"

    scriptsource=""

    # Vnet
    vnet="ctfVnet"                          # change to "vnet-${project}"
    twooctets="10.250"
    ipsubnet="${twooctets}.0.0/16"

    utilsubnet="${twooctets}.240.0/24"
    guacsubnet="${twooctets}.250.0/24"
    ctfdsubnet="${twooctets}.251.0/24"
    appgwsubnet="${twooctets}.252.0/24"

    utilsubnetname="subnetUtility"
    guacsubnetname="subnetGuacamole"
    ctfdsubnetname="subnetCTFd"
    appgwsubnet="subnetAppGw"

    # AppGw

    # VMs Common

    ctfadmin="ctfadmin"
    kaliadmin="kaliadmin"

    linuximage="Canonical:UbuntuServer:18.04-LTS:latest"
    linuxsku="Standard_DS1_v2"
    kaliimage="kali-linux:kali:kali-20231:2023.1.0"
    kalisku="Standard_DS1_v2"

    vmprefix="vm"

    # MySQL Database

    mysqlsku=B_Gen5_1
    mysqlsvr="mysql-${project}"
    mysqlsvrurl="${mysqlsvr}.mysql.database.azure.com"
    mysqladmin="${project}-admin"
    mysqlpassword=`randpassword`

    echo "[**** Make note! MySQL admin creds ${mysqladmin}:${mysqlpassword} ****]"

    guacdb="guacamoledb"
    ctfddb="ctfd"

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

    az mysql server create \
    --resource-group $resgrp \
    --name $mysqlsvr \
    --location $location \
    --admin-user $mysqladmin \
    --admin-password $mysqlpassword \
    --sku-name $dbvmsku \
    --storage-size 51200 \
    --ssl-enforcement Disabled

    az mysql server firewall-rule create \
    --resource-group $resgrp \
    --server $mysqlsvr \
    --name AllowAllForBuild \
    --start-ip-address 0.0.0.0 \
    --end-ip-address 255.255.255.255

}

buildfirewalls () {

    echo "Building Firewalls and Rules"

    # Network Security Groups
    az network nsg create --resource-group $resgrp --name "nsg$(utilsubnetname)"
    az network nsg create --resource-group $resgrp --name "nsg$(guacsubnetname)"
    az network nsg create --resource-group $resgrp --name "nsg$(ctfdsubnetname)"
    az network nsg create --resource-group $resgrp --name "nsg$(appgwsubnetname)"

    # Rules



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
    --public-ip-address "Standard" \
    --no-wait \
    --vnet-name $vnet \
    --subnet $utilsubnetname \
    --nsg "nsg$(utilsubnetname)" 

}


builddockersvr () {

    # The util server has certbot tools and ssh private keys

    local vmname="${vmprefix}-UtilServer"

    az vm create --name $vmname \
    --resource-group $resgrp \
    --size $linuxsku \
    --image $linuximage \
    --admin-username $ctfadmin \
    --generate-ssh-keys \
    --public-ip-address "Standard" \
    --no-wait \
    --vnet-name $vnet \
    --subnet $utilsubnetname \
    --nsg "nsg$(utilsubnetname)" 

    # Deploy application



}


buildkali () {





}


