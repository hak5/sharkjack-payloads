#!/bin/bash
#
# Title:         Port-Sweep
# Author:        Marmeus
# Version:       1.3
# Category:      recon
# Description:   Scans a list of IPs for an open port (default 445) and saves timestamped results.
#
# LED B SOLID   (Blue solid)           Waiting for DHCP lease
# LED ATTACK    (Yellow single blink)  Scanning with nmap -p $PORT
# LED FINISH    (Green burst→solid)    Scan completed successfully
# LED FAIL      (Red slow blink)       Scan failed or TARGETS is empty
#
# Deploy instructions:
#   Copy payload.sh to the SharkJack payload directory.
#   Set TARGETS and PORT in the Options block below before deploying.
#   Results are saved to /root/loot/port_sweep/YYYY-MM-DD-HHMM_port_<PORT>_scan.txt

#  Options 
PORT=445                              # OPTIONAL: port to scan
TARGETS="192.168.1.0/24"             # REQUIRED: space-separated IPs or CIDR ranges
                                      # e.g. "192.168.1.1 10.0.0.0/24 172.16.5.20"
LOOT_DIR=/root/loot/port_sweep       # OPTIONAL

#  Setup: Blue → wait for DHCP 
LED B SOLID
mkdir -p "$LOOT_DIR"

SCREEN_WRITE "[*] Port-Scanner port: $PORT"
SCREEN_WRITE "[*] Starting NETMODE DHCP_CLIENT"
NETMODE DHCP_CLIENT
sleep 2

SCREEN_WRITE "[*] Waiting for eth0 IP..."
while ! ip addr show eth0 | grep "inet " > /dev/null 2>&1; do sleep 1; done
SCREEN_WRITE "[*] Got IP: $(ip addr show eth0 | grep 'inet ' | awk '{print $2}')"

#  Validate TARGETS 
if [ -z "$TARGETS" ]; then
  SCREEN_WRITE "[!] FAIL: TARGETS variable is empty"
  LED FAIL
  sleep 2 && sync
  exit 1
fi
TARGET_COUNT=$(echo $TARGETS | wc -w)
SCREEN_WRITE "[*] Targets: $TARGET_COUNT"

#  Attack: Yellow → nmap scan on $PORT 
TIMESTAMP=$(date +"%Y-%m-%d-%H%M")
OUTPUT_FILE="$LOOT_DIR/${TIMESTAMP}_port_${PORT}_scan.txt"
SCREEN_WRITE "[*] LED yellow - scanning port $PORT"
SCREEN_WRITE "[*] Output: $OUTPUT_FILE"

LED ATTACK
nmap -p "$PORT" --open $TARGETS -oN "$OUTPUT_FILE"
NMAP_EXIT=$?
SCREEN_WRITE "[*] nmap exit code: $NMAP_EXIT"

OPEN_COUNT=$(grep -c "${PORT}/tcp open" "$OUTPUT_FILE" 2>/dev/null || echo 0)

#  Finish: Green on success, Red on failure 
if [ $NMAP_EXIT -eq 0 ]; then
  SCREEN_WRITE "[*] SUCCESS - $OPEN_COUNT host(s) found on port $PORT"
  LED FINISH
else
  SCREEN_WRITE "[!] FAIL - nmap returned $NMAP_EXIT - LED red"
  LED FAIL
fi

sleep 2 && sync
