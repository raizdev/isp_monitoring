#!/bin/bash
if ! [ -x "$(command -v git)" ]; then
  echo 'Error: git is not installed. First install git with the following command: sudo apt install git' >&2
  exit 1
fi

if ! grep -Fxq "mktp" ./docker-compose.yml
then
    git stash
fi

default_ip_address=$(hostname -I | awk '{print $1}')

echo  "Local Device IP Address: $default_ip_address" 

read -p "Is this correct? (Y/n)?: " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || read -p "Enter Local Device IP Address : " new_ip_address

read -p "Do you use a microtik as a router and do you want to use this dashboard (Y/n)?: " confirm && [[ $confirm == [nN] || $confirm == [nN][eE][sS] ]] || read -p "Enter Mikrotik Device IP Address : " mikrotik_ipaddress

[ ! -z "$new_ip_address" ] && ip_address=$new_ip_address || ip_address=$default_ip_address

sed -i "s/local_ip/$ip_address/g" ./prometheus/prometheus.yml
sed -i "s/local_ip/$ip_address/g" ./.env

if [ ! -z "$mikrotik_ipaddress" ]
then
  sed -i "s/mikrotik_ip/$mikrotik_ipaddress/g" ./.env 
  sed -i "s/ping/mikrotik/g" ./.env 

  sed -i "s/mktxp_host/$mikrotik_ipaddress/g" ./mktxp/mktxp.conf 

  read -p "Mikrotik API user: " mikrotik_username  
  sed -i "s/mktxp_user/$mikrotik_username/g" ./mktxp/mktxp.conf 
  read -p "Mikrotik API password: " mikrotik_password
  sed -i "s/mktxp_user_password/$mikrotik_password/g" ./mktxp/mktxp.conf 
else
  sed -i.bak -e '95,103d' ./docker-compose.yml
  rm -rf ./grafana/provisioning/dashboards/isp_monitoring/mikrotik.json
  sed -i.bak -e '22,33d' ./prometheus/prometheus.yml
  rm -rf ./mktxp
fi

echo 'Writing files done...'

sleep 1

echo "Processing installer with `uname -i` as architecture"

architecture=""

arch=$(uname -i)
if [[ $arch == x86_64* ]]; then
    architecture="sethwv\/speedflux"
elif [[ $arch == i*86 ]]; then
    architecture="sethwv\/speedflux"
elif  [[ $arch == arm* ]] || [[ $arch = aarch64 ]]; then
    architecture="raizdev\/speedflux"
fi

sed -i "s/architecture_image/$architecture/g" ./.env

sleep 2

if [ -x "$(command -v docker)" ]; then
    sudo docker compose up -d
else
    echo 'Installing docker...'

    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
      
    sudo apt-get update
    
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    sudo docker compose up -d
fi
