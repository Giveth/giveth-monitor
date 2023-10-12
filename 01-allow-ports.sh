#!/bin/bash

# Check if ports are already open
PORTS=(8080 9100 9080)

echo "Running this will be opening Ports 8080, 9100 and 9080 in ufw."
read -p "Do you want to continue? (y/n) " answer

if [[ $answer == "y" ]]; then
    sudo ufw route allow proto tcp from any to any port 9080
    sudo ufw route allow proto tcp from any to any port 9100
    sudo ufw route allow proto tcp from any to any port 8080
    echo "Ports 8080, 9100 and 9080 opened in ufw."
else
    echo "Operation aborted."
    exit 0
fi

