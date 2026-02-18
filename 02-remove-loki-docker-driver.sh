#!/usr/bin/env bash
# Removes the Loki Docker log driver plugin and cleans up daemon.json.
# Run this on servers where 02-install-loki-docker-log-driver.sh was previously executed.
# Alloy handles all log shipping now — the Docker log driver caused double-ingestion.
#
# Order matters: daemon.json must be cleaned FIRST, then Docker restarted,
# then the plugin can be removed. Otherwise Docker refuses to cooperate
# because it keeps trying to use the disabled loki driver.

set -euo pipefail

echo "=== Removing Loki Docker log driver ==="

# Step 1: Clean up daemon.json FIRST (breaks the circular dependency)
if [[ -f /etc/docker/daemon.json ]]; then
  if grep -q '"log-driver".*loki' /etc/docker/daemon.json; then
    echo "Found loki log-driver in /etc/docker/daemon.json"
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
      echo "Cannot proceed — daemon.json must be cleaned before the plugin can be removed."
      echo "Please manually edit /etc/docker/daemon.json to remove the loki log-driver entries, then restart Docker."
      exit 1
    fi
  else
    echo "/etc/docker/daemon.json does not reference loki — OK."
  fi
else
  echo "No /etc/docker/daemon.json found — OK."
fi

# Step 2: Now remove the plugin (Docker can function normally again)
if docker plugin ls --format '{{.Name}}' | grep -q "loki"; then
  echo ""
  echo "Removing loki plugin..."
  docker plugin disable loki --force 2>/dev/null || true
  docker plugin rm loki --force
  echo "Plugin removed."
else
  echo "Loki plugin not found — nothing to remove."
fi

echo ""
echo "Done. Alloy now handles all log shipping to Loki."
