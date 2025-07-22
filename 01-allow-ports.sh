#!/usr/bin/env bash
# Keep INPUT + FORWARD rules, but wipe any old "ALLOW FWD Anywhere" first.

TRUSTED_IP="165.227.143.82"
PORTS=(8080 9080 9100)

# Delete the wide-open forward rules to make sure
sudo ufw --force route delete allow proto tcp to any port 8080
sudo ufw --force route delete allow proto tcp to any port 9100

for p in "${PORTS[@]}"; do
  ## INPUT ##
  ufw --force delete allow proto tcp from "$TRUSTED_IP" to any port "$p" 2>/dev/null || true
  ufw --force delete deny  proto tcp                     to any port "$p" 2>/dev/null || true
  ufw --force insert 1 allow proto tcp from "$TRUSTED_IP" to any port "$p"
  ufw --force insert 2 deny  proto tcp                     to any port "$p"

  ## FORWARD / route ##
  # 1) wipe every existing route-rule on that port (with or without a 'from')
  ufw --force route delete allow proto tcp                     to any port "$p" 2>/dev/null || true
  ufw --force route delete deny  proto tcp                     to any port "$p" 2>/dev/null || true
  ufw --force route delete allow proto tcp from "$TRUSTED_IP" to any port "$p" 2>/dev/null || true

  # 2) re-insert clean pair
  ufw --force route insert 1 allow proto tcp from "$TRUSTED_IP" to any port "$p"
  ufw --force route insert 2 deny  proto tcp                     to any port "$p"
done

ufw reload
echo -e "\n== Rules now affecting 8080 / 9080 / 9100 =="
ufw status numbered | grep -E 'FWD|IN' | grep -E ' (8080|9080|9100)/tcp'
