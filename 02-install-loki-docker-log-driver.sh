#!/bin/bash

# Step 1: Check if Loki Docker Driver is already installed
if docker plugin ls | grep -q "loki"; then
    echo "Driver Client already running"
fi

# Step 3: Install the Loki Docker Driver
docker plugin install grafana/loki-docker-driver:2.9.1 --alias loki --grant-all-permissions

# Step 4: Check if /etc/docker/daemon.json exists and has the required content
REQUIRED_CONTENT='{
  "debug": true,
  "log-driver": "loki",
  "log-opts": {
        "loki-url": "https://loki.logs.giveth.io/loki/api/v1/push",
        "loki-batch-size": "400"
    }
}'

if [[ -e /etc/docker/daemon.json ]]; then
    CURRENT_CONTENT=$(cat /etc/docker/daemon.json)
    if [[ "$CURRENT_CONTENT" == "$REQUIRED_CONTENT" ]]; then
        echo "Loki Docker Log driver already enabled"
        exit 1
    else
        echo "Error: /etc/docker/daemon.json exists but content is not as expected."
        exit 1
    fi
else
    # Step 5: If the file does not exist, create it with the content
    echo "$REQUIRED_CONTENT" > /etc/docker/daemon.json
fi

echo "Loki Docker Driver Client installed and configured successfully!"
