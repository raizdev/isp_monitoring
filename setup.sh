#!/bin/bash
function choose_from_menu() {
    local prompt="$1" outvar="$2"
    shift
    shift
    local options=("$@") cur=0 count=${#options[@]} index=0
    local esc=$(echo -en "\e") # cache ESC as test doesn't allow esc codes
    printf "$prompt\n"
    while true
    do
        # list all options (option list is zero-based)
        index=0
        for o in "${options[@]}"
        do
            if [ "$index" == "$cur" ]
            then echo -e " >\e[7m$o\e[0m" # mark & highlight the current option
            else echo "  $o"
            fi
            index=$(( $index + 1 ))
        done
        read -s -n3 key # wait for user to key in arrows or ENTER
        if [[ $key == $esc[A ]] # up arrow
        then cur=$(( $cur - 1 ))
            [ "$cur" -lt 0 ] && cur=0
        elif [[ $key == $esc[B ]] # down arrow
        then cur=$(( $cur + 1 ))
            [ "$cur" -ge $count ] && cur=$(( $count - 1 ))
        elif [[ $key == "" ]] # nothing, i.e the read delimiter - ENTER
        then break
        fi
        echo -en "\e[${count}A" # go up to the beginning to re-render
    done
    # export the selection to the requested output variable
    printf -v $outvar "${options[$cur]}"
}


if ! [ -x "$(command -v git)" ]; then
  echo 'Error: git is not installed. First install git with the following command: sudo apt install git' >&2
  exit 1
fi

. .env
if [ ! "$LOCAL_IP_ADDRESS" = "local_ip" ]
then
  read -p "No default configuration found. Are you sure to start over (Y/n)? " confirm && [[ $confirm == [nN] ||  $confirm == [nN][eE][sS] ]] && exit 1 || git stash
fi

default_ip_address=$(hostname -I | awk '{print $1}')

echo  "Local Device IP Address: $default_ip_address"

read -p "Is this correct? (Y/n)?: " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || read -p "Enter Local Device IP Address : " new_ip_address

read -p "Do you use a microtik as a router and do you want to use this dashboard (Y/n)?: " confirm && [[ $confirm == [nN] || $confirm == [nN][eE][sS] ]] || read -p "Enter Mikrotik Device IP Address : " mikrotik_ipaddress

[ ! -z "$new_ip_address" ] && ip_address=$new_ip_address || ip_address=$default_ip_address

selections=(
"KPN Barendrecht"
"KPN Amstelveen"
"Auto"
)

choose_from_menu "Which speedtest server you want to use? " selected_choice "${selections[@]}"

if [ "${selected_choice}" = "KPN Barendrecht" ]; then
        speedtest_server=53438
elif [ "$selected_choice" = "KPN Amstelveen" ]; then
        speedtest_server=61186
else
        speedtest_server=
fi

sed -i "s/local_ip/$ip_address/g" ./prometheus/prometheus.yml
sed -i "s/local_ip/$ip_address/g" ./.env
sed -i "s/speedtest_id/$speedtest_server/g" ./.env

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
  sed -i.bak -e '86,93d' ./docker-compose.yml
  rm -rf ./grafana/provisioning/dashboards/isp_monitoring/mikrotik.json
  rm -rf ./mktxp
fi

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
