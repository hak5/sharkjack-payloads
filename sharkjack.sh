#!/bin/bash
# Shark Jack
#
# sharkjack.sh - Helper script for linux/OSX for convenient interaction with your Hak5 Shark Jack
# (C) Hak5 2019
#VERSION=1.0.0

function exitscript(){
  echo -e "\nExited\n"
  exit $1
}

function err() {
  echo -e "\n[FATAL] $1\n"
  exitscript 1
}

function cleart() {
  printf "\033c"
}

function banner(){
  cleart
  echo -e "\n\n\n\n########################################################\n\n\n"
printf "\
    \_____)\_____      Shark Jack      _____/(_____/
    /--v____ __°<       by Hak5        >°__ ____v--\\
           )/                              \(
"
  echo -e "\n\n########################################################\n\n"
}

function iptables_check() {
  if [[ -z $(which iptables) ]]; then
    err "[!] iptables required to detect Shark on linux"
  fi
}

function os_check() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "\nOSX Detected\n"
    OS=1
  elif [[ "$OSTYPE" == "cygwin" ]]; then
    err "Cygwin not supported"
  else
    OS=0
    iptables_check
  fi
}

function root_check() {
  if [[ "$EUID" -ne 0 ]]; then
    printf "\n%s\n" "Please re-run as root"
    exitscript 1
  fi
}

function connection_error(){
  IFACE=''
  printf "\n%s\n" "[!] error communicating with the Shark Jack"
}

function connection_check(){
  sleep 1
  ping -c 1 172.16.24.1 &>/dev/null && echo -e " [+] Shark Jack Detected..." && return 0
  connection_error && return 1
}


function locate_interface_to_shark() {
  printf "\n%s" 'Waiting for a Shark Jack to be connected..'
  while [[ -z $IFACE ]]; do
    printf "%s" .
    IFACE=$(ip route show to match 172.16.24.1 2>/dev/null| grep -i 172.16.24.1 | cut -d ' ' -f3 | grep -v 172.16.24.1)
    sleep 1
  done
  echo -e "\n"
  connection_check || locate_interface_to_shark
}

function osx_locate_interface_to_shark(){
  printf "\n%s" 'Waiting for a Shark Jack to be connected..'
  while [[ -z $IFACE ]]; do
    printf "%s" .
    IFACE=$(ifconfig |cut -d ' ' -f1 |grep en|cut -d ':' -f1 | xargs -I {} sh -c "ipconfig getifaddr {}|grep -i 172.16.24 &>/dev/null && echo {}")
    sleep 1
  done
  echo -e "\n"
  connection_check || osx_locate_interface_to_shark
}

function locate_shark(){
  if [[ $OS -eq 1 ]]; then
    osx_locate_interface_to_shark
  else
    locate_interface_to_shark
  fi
}

function ssh_connect(){
  printf "\n\tLogging into Shark Jack...\n\n"
  printf "\n\t[!] Ensure Shark Jack is in Arming Mode (middle switch position) or connection will be refused...\n\n\n"
	ssh root@172.16.24.1 || return 1
}

function connect() {
  locate_shark
  printf "\n\tAttempting to establish SSH connection...\n"
  ssh_connect || return 1
}

function check_ip6tables_rule_exists(){
  if [[ -z $(ip6tables -vL|grep $IFACE) ]];then
    echo 1
  else
    echo 0
  fi
}

function cleanup() {
  printf "\n%s\n" "[!] Cleaning up..."
}

function get_payload_path(){
  read -p "FULL PATH to payload (q to return to menu): " PAYLOADPATH
  if [[ $PAYLOADPATH == "q" ]]; then
    cleart
    printf "\n%s\n" "[!] Returning to main menu..."
    sleep 2
    main_menu
  else
    [[ ! -e $PAYLOADPATH ]] && printf "\n%s\n" "[!] $PAYLOADPATH does not exist" && sleep 2 && main_menu
  fi
}

function push_payload(){
  echo -e "\n [+] Push Payload to Shark Jack"
  echo -e "\n----------------------------------------"
  get_payload_path
  locate_shark
  echo -e "\n [+] Pushing payload to device..."
  EXPANDEDPATH=$(echo $PAYLOADPATH |cd)
  scp -r $EXPANDEDPATH root@172.16.24.1:/root/payload/payload.txt && echo -e "\n [+] Payload copied to Shark" || echo -e "\n [!] ERROR copying paylod to Shark"
  exitscript 0
}

function connect_and_upgrade(){
    echo -e "\n [+] Upgrading Shark Jack firmware"
    echo -e "\n----------------------------------------"
    locate_shark
    upgrade_firmware
}

function path_firmware_upgrade(){
  read -p "Path (including filename) to Shark Jack firmware file (q to return to menu): " FWFILEPATH
  if [[ $FWFILEPATH == "q" ]]; then
    cleart
    printf "\n%s\n" "[!] Returning to main menu..."
    sleep 2
    main_menu
  else
    [[ -z $FWFILEPATH ]] && printf "\n%s\n" "[!] $FWFILEPATH does not exist" && sleep 2&& local_file_menu && main_menu || connect_and_upgrade
  fi
}

function download_latest_fw(){
  echo -e "\n Downloading latest Shark Jack firmware\n"
  echo -e "\n----------------------------------------\n"
  curl -L https://downloads.hak5.org/api/devices/sharkjack/firmwares/latest --output shark-upgrade.bin && echo -e "\n [+] Firmware download complete!\n\n" || err "[!] Firmware Download Failed"
  FWFILEPATH="shark-upgrade.bin"
  connect_and_upgrade
}

function ls_cwd(){
 banner
 echo -e "\n Listing .bin files in current working directory: $(pwd) \n"
 ls -l $(pwd) |grep -i '.bin'
 echo -e "\n----------------------------------------\n"
 local_file_menu
}

function local_file_menu(){
  echo -e "\n Upgrade Shark Jack firmware using local file"
  echo -e "\n----------------------------------------"
  echo -e "\n Where is the new Shark Jack firmware file located? "
  printf "\n\
  [$(tput bold)L$(tput sgr0)]ist bins in current directory\n\
  \n\
  [$(tput bold)P$(tput sgr0)]rovide path to file\n\n\
  [$(tput bold)M$(tput sgr0)]ain Menu\n\
  [$(tput bold)Q$(tput sgr0)]uit\n\n"

  read  -r -sn1 key
  case "$key" in
          [lL]) ls_cwd;;
          [pP]) path_firmware_upgrade;;
          [mM]) main_menu;;
          [qQ]) exitscript 0;;
          *) local_file_menu;;
  esac
}

function reset_key(){
  printf "\n\tRemoving Shark Jack key from known_hosts file...\n\n"
  HOMEDIR=$(eval echo "~$USER")
  ssh-keygen -f "$HOMEDIR/.ssh/known_hosts" -R 172.16.24.1
}

function do_sysupgrade(){
  printf "\n%s\n" "User Confirmed Power Source, continuing with upgrade..."
  echo -e "\n Shark Jack Firmware Upgrade"
  echo -e "\n----------------------------------------"
  printf "\n%s\n\n" "Logging into Shark Jack to Start Upgrade..."

  ssh root@172.16.24.1 -t 'sysupgrade -n /tmp/upgrade.bin'
  trap '' SIGINT

  banner
  printf "\n%s\n" "[!] DO NOT UNPLUG THE DEVICE UNTIL IT HAS REBOOTED"
  printf "\n%s\n" "[!] Shark Jack Firmware Upgrading..."
  COUNT=0
  while [[ $COUNT -lt 146 ]]; do
    printf "%s" .
    COUNT=($COUNT+1)
    sleep 1
  done
  trap - SIGINT

  reset_key
  printf "\n%s\n" "Ready to attempt reconnection to your newly upgraded Shark Jack..."
  exitscript 0
}

function upgrade_firmware(){
  printf "\n%s\n\n" "Copying Firmware to Shark Jack..."
  scp $FWFILEPATH root@172.16.24.1:/tmp/upgrade.bin

  cleart
  printf "\n%s\n" "ONCE STARTED - DO NOT UNPLUG THE DEVICE FROM NETWORK OR POWER"
  printf "\n%s\n" "[!] SHARK JACK MUST BE POWERED OVER USB-C [!]"
  printf "\n%s\n" "[!][!] Attempting Firmware Upgrade ON BATTERY will likely brick your device. [!][!]"
  echo -e "\nFirmware File to Flash: $FWFILEPATH"
  ls -lah $FWFILEPATH
  echo "Checksum:"
  sha256sum $FWFILEPATH
  echo -e "\nIs your Shark Jack connected to a good power source and is the file listed above correct?"
  printf "\n\
  [$(tput bold)Y$(tput sgr0)]es / Continue\n\
  [$(tput bold)N$(tput sgr0)]o / Abort\n\n\
  [$(tput bold)M$(tput sgr0)]ain Menu / Abort\n\
  [$(tput bold)Q$(tput sgr0)]uit / Abort\n\n"

  read -r -sn1 key
  case "$key" in
          [yY]) do_sysupgrade;;
          [nN]) echo -e "\n[!] Connect Shark Jack to Power over USB-C to upgrade firmware"; exitscript 1;;
          [mM]) main_menu;;
          [qQ]) exitscript 0;;
          *) echo -e "\n Unrecognized response, Exiting for safety"; exitscript 1;;
  esac
}

function upgrade_process_menu(){
  banner
  echo -e "\n Shark Jack Firmware Upgrade Menu"
  echo -e "\n----------------------------------------\n"
  printf "\n\
  [$(tput bold)D$(tput sgr0)]ownload latest firmware from downloads.hak5.org\n\
  [$(tput bold)L$(tput sgr0)]ocal firmware file\n\n\
  [$(tput bold)M$(tput sgr0)]ain Menu\n\
  [$(tput bold)Q$(tput sgr0)]uit\n\n"

  read -r -sn1 key
  case "$key" in
          [lL]) banner && local_file_menu;;
          [dD]) banner && download_latest_fw;;
          [mM]) main_menu;;
          [qQ]) exitscript 0;;
          *) upgrade_process_menu;;

  esac
}

function get_loot(){
  locate_shark
  printf "\n%s\n\n" "Logging into Shark Jack to pull collected loot..."
  scp -r root@172.16.24.1:/root/loot/ .
  exitscript 0
}

function setup_shark(){
  locate_shark
  echo -e "\nCopy ssh key to shark for passwordless login"
  echo -e "\n------------------------------------------------\n"
  HOMEDIR=$(eval echo "~$USER")
  echo -e "\n Listing : $HOMEDIR/.ssh \n"
  ls -l $HOMEDIR/.ssh
  echo -e "\n----------------------------------------\n"

  if [[ -z $(ls -l $HOMEDIR/.ssh|grep -i .pub) ]]; then
    echo -e "\nNo key found. Calling ssh-keygen to create a new one...\n"
    ssh-keygen -t rsa -b 4096
  fi

  read -p "FULL PATH to your SSH key or hit enter to use the default ~/.ssh/id_rsa.pub (q to return to menu): " SSHKEYPATH
  if [[ $SSHKEYPATH == "q" ]]; then
    cleart
    printf "\n%s\n" "[!] Returning to main menu..."
    sleep 2
    main_menu
  else
    [[ -e $SSHKEYPATH ]] && printf "\n%s\n" "[!] $SSHKEYPATH does not exist" && sleep 2 && main_menu
  fi
  if [[ -z $SSHKEYPATH ]]; then
    ssh-copy-id -i root@172.16.24.1
  else
    ssh-copy-id -i $SSHKEYPATH "root@172.16.42.1"
  fi
  exitscript 0
}

function main_menu() {
   banner
   if [[ $OS -eq 1 ]]; then
      echo -e "\n\n OSX DETECTED \n\n"
   fi
   printf "\n\
   Press the highlighted key to select an option (example: press C to connect)\n\n\
   [$(tput bold)C$(tput sgr0)]onnect - get a shell on your Shark Jack\n\
   [$(tput bold)U$(tput sgr0)]pgrade firmware\n\
   [$(tput bold)P$(tput sgr0)]ush payload to Shark Jack\n\
   [$(tput bold)G$(tput sgr0)]et loot saved on Shark Jack\n\n\
   [$(tput bold)R$(tput sgr0)]eset known_hosts keys for the Shark Jack on this system\n\
   [$(tput bold)S$(tput sgr0)]etup ssh keys for easy access\n\
   [$(tput bold)Q$(tput sgr0)]uit\n\n"

   read -r -sn1 key
   case "$key" in
          [cC]) connect;;
 	  [uU]) upgrade_process_menu;;
	  [pP]) push_payload;;
          [gG]) get_loot;;
          [rR]) reset_key;;
          [sS]) setup_shark;;
          [qQ]) exitscript 0;;
          *) main_menu;;
   esac
}

# Validate priv / iptables
root_check
os_check

main_menu

echo -e "\nDone\n"

trap cleanup INT
exitscript 0
