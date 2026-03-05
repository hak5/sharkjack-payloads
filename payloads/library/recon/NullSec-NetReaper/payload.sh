#!/bin/bash
#
# Title:         NullSec-NetReaper
# Author:        bad-antics (NullSec)
# Category:      Recon
# Target:        Any network
# Version:       1.0
#
# Description:   Comprehensive network reconnaissance payload for the Shark Jack.
#                Performs ARP scan, port scanning, service identification, LLDP/CDP
#                neighbor discovery, DHCP fingerprinting, and subnet enumeration.
#                Zero external dependencies — uses only built-in tools.
#
# LED States:
#   SETUP  (Magenta) - Initializing
#   ATTACK (Yellow)  - Scanning in progress
#   FINISH (Green)   - Complete, safe to remove
#   FAIL   (Red)     - Error occurred

SERIAL_WRITE [*] NullSec-NetReaper v1.0 starting...

# ================================
# Configuration
# ================================
SCAN_TIMEOUT=120          # Max scan time in seconds
TOP_PORTS=100             # Number of top ports to scan
LOOT_DIR=/root/loot/netreaper_$(date +%Y%m%d_%H%M%S)
NETMODE DHCP_CLIENT

# ================================
# Setup Phase
# ================================
LED SETUP

mkdir -p "$LOOT_DIR"
LOG="$LOOT_DIR/recon_report.txt"

# Wait for network
SERIAL_WRITE [*] Waiting for network...
sleep 5

# Detect network configuration
SUBNET=$(ip route | grep -v default | grep -v 169.254 | head -1 | awk '{print $1}')
GATEWAY=$(ip route | grep default | awk '{print $2}')
IFACE=$(ip route | grep default | awk '{print $5}')
MY_IP=$(ip -4 addr show "$IFACE" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
DNS=$(cat /etc/resolv.conf | grep nameserver | head -1 | awk '{print $2}')

if [ -z "$SUBNET" ] || [ -z "$MY_IP" ]; then
    LED FAIL
    SERIAL_WRITE [!] Failed to get network configuration
    exit 1
fi

SERIAL_WRITE "[+] Connected: $MY_IP on $SUBNET (gw: $GATEWAY)"

# ================================
# Scan Phase
# ================================
LED ATTACK

{
    echo "============================================================"
    echo "  NullSec-NetReaper Network Reconnaissance Report"
    echo "  $(date)"
    echo "============================================================"
    echo ""

    # --- Network Configuration ---
    echo "[+] NETWORK CONFIGURATION"
    echo "    Interface:  $IFACE"
    echo "    IP Address: $MY_IP"
    echo "    Subnet:     $SUBNET"
    echo "    Gateway:    $GATEWAY"
    echo "    DNS:        $DNS"
    echo "    MAC:        $(cat /sys/class/net/$IFACE/address 2>/dev/null)"
    echo ""

    # --- ARP Discovery ---
    echo "[+] ARP DISCOVERY"
    echo "    Performing ARP scan..."

    # Ping sweep for discovery
    NETWORK_BASE=$(echo "$SUBNET" | cut -d'/' -f1 | sed 's/\.[0-9]*$//')
    for i in $(seq 1 254); do
        ping -c 1 -W 1 "${NETWORK_BASE}.$i" &>/dev/null &
    done
    wait
    sleep 2

    # Collect ARP table
    ARP_RESULTS=$(arp -an 2>/dev/null | grep -v incomplete | grep -oP '\(\K[^\)]+')
    HOST_COUNT=$(echo "$ARP_RESULTS" | grep -c .)
    echo "    Found $HOST_COUNT live hosts:"
    echo ""
    arp -an 2>/dev/null | grep -v incomplete | while read line; do
        echo "    $line"
    done
    echo ""

    # --- Port Scanning ---
    echo "[+] PORT SCANNING (Top ports on discovered hosts)"
    COMMON_PORTS="21,22,23,25,53,80,110,111,135,139,143,443,445,993,995,1433,1521,3306,3389,5432,5900,8080,8443,8888,9090"

    for HOST in $ARP_RESULTS; do
        if [ "$HOST" = "$MY_IP" ]; then continue; fi
        echo ""
        echo "    --- Host: $HOST ---"

        OPEN_PORTS=""
        for PORT in $(echo "$COMMON_PORTS" | tr ',' ' '); do
            (echo >/dev/tcp/$HOST/$PORT) 2>/dev/null && OPEN_PORTS="$OPEN_PORTS $PORT"
        done

        if [ -n "$OPEN_PORTS" ]; then
            echo "    Open ports:$OPEN_PORTS"

            # Service identification
            for PORT in $OPEN_PORTS; do
                case $PORT in
                    21)  SVC="FTP" ;;
                    22)  SVC="SSH" ;;
                    23)  SVC="Telnet" ;;
                    25)  SVC="SMTP" ;;
                    53)  SVC="DNS" ;;
                    80)  SVC="HTTP" ;;
                    110) SVC="POP3" ;;
                    135) SVC="MSRPC" ;;
                    139) SVC="NetBIOS" ;;
                    143) SVC="IMAP" ;;
                    443) SVC="HTTPS" ;;
                    445) SVC="SMB" ;;
                    1433) SVC="MSSQL" ;;
                    1521) SVC="Oracle" ;;
                    3306) SVC="MySQL" ;;
                    3389) SVC="RDP" ;;
                    5432) SVC="PostgreSQL" ;;
                    5900) SVC="VNC" ;;
                    8080) SVC="HTTP-Proxy" ;;
                    8443) SVC="HTTPS-Alt" ;;
                    *)   SVC="Unknown" ;;
                esac
                echo "      $PORT/tcp  $SVC"
            done
        else
            echo "    No common ports open (or host filtered)"
        fi
    done
    echo ""

    # --- Gateway Analysis ---
    echo "[+] GATEWAY ANALYSIS ($GATEWAY)"
    echo "    Traceroute:"
    traceroute -m 5 -w 2 8.8.8.8 2>/dev/null | head -10 | while read line; do
        echo "    $line"
    done
    echo ""

    # --- DHCP Information ---
    echo "[+] DHCP LEASE INFORMATION"
    if [ -f /tmp/dhcp.leases ]; then
        cat /tmp/dhcp.leases | while read line; do
            echo "    $line"
        done
    fi
    echo ""

    # --- DNS Enumeration ---
    echo "[+] DNS RECONNAISSANCE"
    if command -v nslookup &>/dev/null; then
        echo "    Reverse DNS for discovered hosts:"
        for HOST in $ARP_RESULTS; do
            RDNS=$(nslookup "$HOST" 2>/dev/null | grep "name = " | awk '{print $NF}')
            if [ -n "$RDNS" ]; then
                echo "      $HOST -> $RDNS"
            fi
        done
    fi
    echo ""

    # --- Network Services Detection ---
    echo "[+] BROADCAST/MULTICAST DISCOVERY"
    # Capture broadcast traffic for 10 seconds
    if command -v tcpdump &>/dev/null; then
        timeout 10 tcpdump -i "$IFACE" -c 50 broadcast or multicast 2>/dev/null | \
            grep -oP 'IP \K[^ ]+' | sort -u | while read src; do
                echo "    Broadcast source: $src"
            done
    fi
    echo ""

    # --- Summary ---
    echo "============================================================"
    echo "  SCAN SUMMARY"
    echo "  Hosts discovered: $HOST_COUNT"
    echo "  Subnet: $SUBNET"
    echo "  Duration: $SECONDS seconds"
    echo "============================================================"

} > "$LOG" 2>&1

# Save raw ARP table
arp -an > "$LOOT_DIR/arp_table.txt" 2>/dev/null

# Save interface details
ip addr > "$LOOT_DIR/interfaces.txt" 2>/dev/null
ip route > "$LOOT_DIR/routes.txt" 2>/dev/null

SERIAL_WRITE "[+] Scan complete. Loot saved to $LOOT_DIR"
SERIAL_WRITE "[+] Hosts found: $HOST_COUNT"

LED FINISH
