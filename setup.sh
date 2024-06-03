#!/bin/bash
default_ip_address=$(hostname -I | awk '{print $1}')

echo  "Local Device IP Address: $default_ip_address" 

read -p "Is this correct? (Y/n)?: " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || read -p "Enter Local Device IP Address : " new_ip_address

read -p "Do you use a microtik as a router and do you want to use this dashboard (Y/n)?: " confirm && [[ $confirm == [nN] || $confirm == [nN][eE][sS] ]] || read -p "Enter Mikrotik Device IP Address : " mikrotik_ipaddress

[ ! -z "$new_ip_address" ] && ip_address=$new_ip_address || ip_address=$default_ip_address

echo "Updating .env local_ip to $ip_address and mikrotik_ip to $mikrotik_ipaddress"

sed -i "s/local_ip/$ip_address/g" ./prometheus/prometheus.yml
sed -i "s/local_ip/$ip_address/g" ./.env

[ -z "$mikrotik_ipaddress" ] || sed -i "s/mikrotik_ip/$mikrotik_ipaddress/g" ./.env 
[ ! -z "$mikrotik_ipaddress" ] || sed -i.bak -e '97,105d' ./docker-compose.yml
[ ! -z "$mikrotik_ipaddress" ] || sed -i.bak -e '22,33d' ./prometheus/prometheus.yml

echo 'Writing files done...'

sleep 1

echo "Setting architecture in .env to `uname -i`"

architecture=""

arch=$(uname -i)
if [[ $arch == x86_64* ]]; then
    architecture="sethwv\/speedflux"
elif [[ $arch == i*86 ]]; then
    architecture="sethwv\/speedflux"
elif  [[ $arch == arm* ]] || [[ $arch = aarch64 ]]; then
    architecture="raizdev\/speedflux"
fi

echo $architecture

sed -i "s/architecture_image/$architecture/g" ./.env

sleep 3

echo 'Installing docker...'

sleep 2

#debug mode
set -x  # Enable debug mode
# Update package list
sudo apt update

# Install dependencies
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Add Docker repository
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Update package list again
sudo apt update

# Install Docker
sudo apt install -y docker-ce

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to the docker group (optional, to run Docker without sudo)
sudo usermod -aG docker $USER

# Install Docker Compose (optional)
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

set +x  # Disable debug mode

echo 'Docker installation done..'

sleep 2

sudo docker compose up -d
