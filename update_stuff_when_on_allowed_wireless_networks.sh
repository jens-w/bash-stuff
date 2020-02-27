#!/bin/bash

VERBOSE=1
WHICH=$((which nmcli) 2>&1)

if [[ $WHICH == *"which: no"* ]]; then
    echo ".:: `date` nmcli is not installed, aborting..."
    exit
fi

wifi_network=$(nmcli -t -f active,ssid dev wifi | grep "^yes" | cut -d\: -f2)
# config file containing allowed networks, one network per line
config_file=/data/xena/wireless.conf

if [[ ! -f $config_file ]]; then
    echo ".:: `date` config file $config_file does not exist"
    exit
fi

readarray allowed_networks < $config_file

for network in ${allowed_networks[@]}; do
    if [ "$network" == "$wifi_network" ]; then
        # if root
        if [ "$EUID" == 0 ]; then
            pacman -Syy
        else
            cd ~/GitHub/liquidprompt
            UPDATED=$(git pull)
            
            cd ~/GitHub/pikaur
            UPDATED=$(git pull)
        fi
    fi
done
