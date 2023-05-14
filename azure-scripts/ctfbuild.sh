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
    export project="script-test"
    export location="uksouth"
    export resgrp="rg-${project}"

    export scriptsource="https://raw.githubusercontent.com/daemonchild/ccc-ctf-may23/main/setup-scripts"

    # Vnet
    export vnet="vnet-${project}"                          # (ctfVnet)
    export twooctets="10.150"
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

    # VMs Common

    export ctfadmin="ctfadmin"
    export kaliadmin="kaliadmin"

    export linuximage="Canonical:UbuntuServer:18.04-LTS:latest"
    export linuxsku="Standard_DS1_v2"
    export kaliimage="kali-linux:kali:kali-20231:2023.1.0"
    export kalisku="Standard_DS1_v2"

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
    export mysqladmin="${project}-admin"
    export mysqlpassword=`randpassword`

    echo "[**** Make note! MySQL admin creds ${mysqladmin}:${mysqlpassword} ****]"

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
    az network nsg create --resource-group $resgrp --name "nsg-$(utilsubnetname)"
    az network nsg create --resource-group $resgrp --name "nsg-$(guacsubnetname)"
    az network nsg create --resource-group $resgrp --name "nsg-$(ctfdsubnetname)"
    az network nsg create --resource-group $resgrp --name "nsg-$(appgwsubnetname)"

    az network nsg create --resource-group $resgrp --name "nsg-$(appgwsubnetname)"

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

buildctfdsvr () {

    # CTFd Server for Scoreboard and Flags
    # Send this id to create

    local id=$1
    local vmname="${vmprefix}-CTFd-${id}"

    az vm create --name $vmname \
    --resource-group $resgrp \
    --size $linuxsku \
    --image $linuximage \
    --admin-username $ctfadmin \
    --generate-ssh-keys \
    --public-ip-address "" \
    --no-wait \
    --vnet-name $vnet \
    --subnet $ctfdsubnetname \
    --nsg "nsg-$(ctfdsubnetname)"

    # Deploy setup script

    az vm run-command invoke -g $resgrp -n $vmname  \
        --command-id RunShellScript \
        --scripts "wget -O ${scriptsource}/docker/setup.sh -O | bash" 

    # add Rules to firewall

}



builddockersvr () {

    # Docker Server used to host challenges

    local team=$1
    local vmname="${vmprefix}-Dockerhost-${team}"
    local staticip="${twooctets}.${team}.${dockerstatic}"

    az network nsg create --resource-group $resgrp --name "nsg-${vmname}"

    az vm create --name $vmname \
    --resource-group $resgrp \
    --size $linuxsku \
    --image $linuximage \
    --admin-username $ctfadmin \
    --generate-ssh-keys \
    --public-ip-address "" \
    --no-wait \
    --vnet-name $vnet \
    --subnet $dockersubnetname \
    --nsg "nsg-${vmname}" 

    # Deploy setup script

    az vm run-command invoke -g $resgrp -n $vmname  \
        --command-id RunShellScript \
        --scripts "wget -O ${scriptsource}/docker/setup.sh -O | bash" 

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

    local subnetname="${challengenetprefix}-${team}"
    local subnet="${twooctets}.${team}.0/24"
    local staticip="${twooctets}.${team}.${kalistatic}"

    subnetname="${snet}-team${i}"
    snetprefix="${ipsubnet}.${i}"
    cidr="${snetprefix}.0/24"

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
    --no-wait \
    --vnet-name $vnet \
    --subnet $subnetname \
    --nsg "nsg-${vmname}" 

    # Deploy setup script

    az vm run-command invoke -g $resgrp -n $vmname  \
        --command-id RunShellScript \
        --scripts "wget -O ${scriptsource}/kali/setup.sh -O | bash" 

    # add Rules to firewall


}


