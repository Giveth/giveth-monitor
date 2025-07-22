#!/usr/bin/env bash

TRUSTED_IP="165.227.143.82"
PORTS=(8080 9080 9100)

for p in "${PORTS[@]}"; do
  #### INPUT (chain that packets hit before DNAT) ####
  ufw delete allow proto tcp from "$TRUSTED_IP" to any port "$p" 2>/dev/null || true
  ufw delete deny  proto tcp                to any port "$p" 2>/dev/null || true
  ufw insert 1 allow proto tcp from "$TRUSTED_IP" to any port "$p"
  ufw insert 2 deny  proto tcp                to any port "$p"

  #### FORWARD (chain that carries traffic to the container after DNAT) ####
  ufw route delete allow proto tcp from "$TRUSTED_IP" to any port "$p" 2>/dev/null || true
  ufw route delete deny  proto tcp                to any port "$p" 2>/dev/null || true
  ufw route insert 1 allow proto tcp from "$TRUSTED_IP" to any port "$p"
  ufw route insert 2 deny  proto tcp                to any port "$p"
done

ufw reload
echo "== Current rules touching 8080/9080/9100 =="
ufw status numbered | grep -E ' (8080|9080|9100)/tcp'
