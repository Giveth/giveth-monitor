#!/usr/bin/env bash
# Removes the Loki Docker log driver plugin and cleans up daemon.json.
# Run this on servers where 02-install-loki-docker-log-driver.sh was previously executed.
# Alloy handles all log shipping now — the Docker log driver caused double-ingestion.

set -euo pipefail

echo "=== Removing Loki Docker log driver ==="

# Step 1: Disable and remove the plugin
if docker plugin ls --format '{{.Name}}' | grep -q "loki"; then
  echo "Disabling loki plugin..."
  docker plugin disable loki --force
  echo "Removing loki plugin..."
  docker plugin rm loki
  echo "Plugin removed."
else
  echo "Loki plugin not found — skipping."
fi

# Step 2: Clean up daemon.json
if [[ -f /etc/docker/daemon.json ]]; then
  if grep -q '"log-driver".*loki' /etc/docker/daemon.json; then
    echo ""
    echo "WARNING: /etc/docker/daemon.json still references the loki log-driver."
    echo "Current contents:"
    echo "---"
    cat /etc/docker/daemon.json
    echo "---"
    echo ""
    read -rp "Replace with minimal daemon.json (removes loki log-driver config)? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      cp /etc/docker/daemon.json /etc/docker/daemon.json.bak
      echo '{}' > /etc/docker/daemon.json
      echo "Saved backup to /etc/docker/daemon.json.bak"
      echo "Wrote clean /etc/docker/daemon.json"
      echo ""
      echo "Restarting Docker daemon..."
      systemctl restart docker
      echo "Docker restarted."
    else
      echo "Skipped. Please manually edit /etc/docker/daemon.json to remove the loki log-driver entries, then restart Docker."
    fi
  else
    echo "/etc/docker/daemon.json exists but does not reference loki — no changes needed."
  fi
else
  echo "No /etc/docker/daemon.json found — nothing to clean up."
fi

echo ""
echo "Done. Alloy now handles all log shipping to Loki."
