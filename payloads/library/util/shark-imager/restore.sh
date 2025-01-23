#!/bin/bash
#
# Title:		restore.sh   
# Description:		Restore backed-up date and install packages on SharkJack
#			Execute with: bash ./restore.sh /path/to/backup.zip (e.g. "bash ./restore.sh /tmp/1-20200101-SharkJack-backup.zip")
#			Copy the backup file to the Shark Jack's /tmp directory via SCP (e.g. "scp 1-20200101-SharkJack-backup.zip root@172.16.24.1:/tmp/")
# Author:		Robert Coemans
# Version:		1.0 (20-08-2020)
# Category:		Util
#
# Dependencies: this payload requires you to have the following packages already installed and configured via 'opkg install' (do 'opkg update' first):
# - curl		= E.g. to grab external IP address and to post notifications
# - unzip
#
# LED indications (https://docs.hak5.org/hc/en-us/articles/360010554653-LED)
# - Setting up		= Magenta solid [LED SETUP]
# - Restoring		= Yellow single blink [LED ATTACK]
# - Finishing up	= Yellow double blink [LED STAGE2]
# - Finished		= Green very fast blinking followed by solid [LED FINISH]

# ****************************************************************************************************
# Configuration
# ****************************************************************************************************

# Setup toggles
NOTIFY_PUSHOVER=true
START_CLOUD_C2_CLIENT=false

# Restore toggles
INSTALL_PACKAGES=false
RESTORE_ONLY_NEWER_FILES=false			# If set to false all files from backup will be restored even older files!

# Finish toggles
EXFIL_TO_CLOUD_C2=true
EXFIL_TO_SCP=false

# Setup variables
RESTORE_DIR_ROOT="/root/restore"		# Be careful, this folder and all its contents including subfolders will be deleted!
TODAY=$(date +%Y%m%d)
START_TIME=$(date)
BATTERY_STATUS=$(BATTERY)
CLOUD_C2_PROVISION="/etc/device.config"

# Restore variables
OPKG_PACKAGES_TO_INSTALL=( "unzip" "zip" "nano" "curl" "lldpd" "bind-dig" "bind-host" "libustream-openssl" )
RESTORE_DESTINATION_USER="{username}"			# Generate a ssh key (ssh-keygen) on the destination host and copy it (~/.ssh/id_rsa_pub) to the SharkJack (~/.ssh/authorized/keys) in order to bypass password!
RESTORE_DESTINATION_HOST="192.168.10.1"
RESTORE_DESTINATION_DIR_ROOT="/some/destination/folder/for/log_file"

# Exfiltrate and notification variables
PUSHOVER_API_POST_URL="https://api.pushover.net/1/messages.json"
PUSHOVER_APPLICATION_TOKEN="{your-application-token}"
PUSHOVER_USER_TOKEN="{your-user-token}"
PUSHOVER_PRIORITY="1"				# send as -2 to generate no notification/alert, -1 to always send as a quiet notification or 1 to display as high-priority and bypass the user's quiet hours!
PUSHOVER_DEVICE="{your-device}"			# Multiple devices may be separated by a comma!

# ****************************************************************************************************
# Setup functions
# ****************************************************************************************************

function CHECK_INPUT_PARAM() {
	if [ $# -lt 1 ]; then
		echo "Please specify the backup.zip file to be restored (e.g. "bash $0 /tmp/1-20200101-SharkJack-backup.zip")."
		exit
	elif [ ! -f "$1" ]; then
		echo "$1 is not an existing file, please specify a backup.zip file to be restored (e.g. "bash $0 /tmp/1-20200101-SharkJack-backup.zip")."
		exit
	elif [ "${1##*.}" == "zip" ]; then
		BACKUP_FILENAME=$(basename $1)
		BACKUP_FILENAME=${BACKUP_FILENAME%.*}
	else
		echo "$1 is not an zip file, please specify a backup.zip file to be restored (e.g. "bash $0 /tmp/1-20200101-SharkJack-backup.zip")."
		exit
	fi
	return
}

function CREATE_RESTORE_FOLDER() {
	if [ -d "$RESTORE_DIR_ROOT" ]; then
		rm -r "$RESTORE_DIR_ROOT"
	fi
	mkdir -p "$RESTORE_DIR_ROOT" > /dev/null
	RESTORE_DIR="$RESTORE_DIR_ROOT/$BACKUP_FILENAME"
	mkdir -p "$RESTORE_DIR" > /dev/null
	return
}

function INITIALIZE_LOG_FILE() {
	LOG_FILE=$RESTORE_DIR_ROOT/$BACKUP_FILENAME-restore.log
	touch $LOG_FILE
	echo "****************************************************************************************************" >> $LOG_FILE
	echo "Restore executed at: $START_TIME" >> $LOG_FILE
	echo "SharkJack battery status: $BATTERY_STATUS" >> $LOG_FILE
	echo "****************************************************************************************************" >> $LOG_FILE
	echo >> $LOG_FILE
	echo "Free diskspace before actions: $(df -h | grep overlayfs | awk {'print $4'})" >> $LOG_FILE
	echo "Restore directory has been created: $RESTORE_DIR" >> $LOG_FILE
	return
}

function RESTORE_STARTED_NOTIFICATION() {
	if [ "$NOTIFY_PUSHOVER" = "true" ]; then
		curl -s --form-string token="$PUSHOVER_APPLICATION_TOKEN" --form-string user="$PUSHOVER_USER_TOKEN" --form-string priority="$PUSHOVER_PRIORITY" --form-string device="$PUSHOVER_DEVICE" --form-string title="SharkJack restore started on date: $(date '+%d-%m-%Y'), time: $(date '+%H:%M')  $(date '+%Z %z')" --form-string message="Restore identifier: $BACKUP_FILENAME" $PUSHOVER_API_POST_URL > /dev/null && echo "Restore started notification has been sent to Pushover" >> $LOG_FILE || echo "Restore started notification has NOT been sent to Pushover as something went wrong" >> $LOG_FILE
	fi
	return
}

function START_CLOUD_C2_CLIENT() {
	if [ "$START_CLOUD_C2_CLIENT" = "true" ]; then
		if [[ -f "$CLOUD_C2_PROVISION" ]]; then
			C2CONNECT
			while ! pgrep cc-client; do sleep 1; done
			echo "Connected to Cloud C2" >> $LOG_FILE
		else
			echo "Cloud C2 client configuration file ($CLOUD_C2_PROVISION) does not exists" >> $LOG_FILE
		fi
	fi
	return
}

# ****************************************************************************************************
# Restore functions
# ****************************************************************************************************

function INSTALL_PACKAGES() {
	if [ "$INSTALL_PACKAGES" = "true" ]; then
		echo "INSTALL_PACKAGES function to be implemented!"
		# Wait until Shark Jack has an IP address                                             
		while [ -z "$IPADDR" ]; do sleep 1 && IPADDR=$(ifconfig eth0 | grep "inet addr"); done
		#opkg update >> $LOG_FILE 2>&1 && echo "opkg (open package management) has been updated succesfully" >> $LOG_FILE || echo "opkg (open package management) has not been (fully) updated" >> $LOG_FILE
		opkg update && echo "opkg (open package management) has been updated succesfully" >> $LOG_FILE || echo "opkg (open package management) has not been (fully) updated" >> $LOG_FILE
		for OPKG_PACKAGE_TO_INSTALL in ${OPKG_PACKAGES_TO_INSTALL[@]}; do
			#opkg install $OPKG_PACKAGE_TO_INSTALL >> $LOG_FILE 2>&1 && echo "Package $OPKG_PACKAGE_TO_INSTALL has been installed succesfully" >> $LOG_FILE || echo "Package $OPKG_PACKAGE_TO_INSTALL has not been installed" >> $LOG_FILE
			opkg install $OPKG_PACKAGE_TO_INSTALL && echo "Package $OPKG_PACKAGE_TO_INSTALL has been installed succesfully" >> $LOG_FILE || echo "Package $OPKG_PACKAGE_TO_INSTALL has not been installed" >> $LOG_FILE
		done
	fi
	return
}

function RESTORE_DATA() {
	unzip $1 -d $RESTORE_DIR && echo "Backup file $1 has been extracted" >> $LOG_FILE || echo "Backup file $1 has NOT been extracted" >> $LOG_FILE
	if [ "$RESTORE_ONLY_NEWER_FILES" = "true" ]; then
		cp -ru $RESTORE_DIR/* / && echo "Files from backup $BACKUP_FILENAME has been restored while skipping existing newer files" >> $LOG_FILE || echo "Something went wrong, no files have been restored" >> $LOG_FILE
	else
		cp -r "$RESTORE_DIR/*" "/" && echo "Files from backup $BACKUP_FILENAME has been restored while overwriting existing files" >> $LOG_FILE || echo "Something went wrong, no files have been restored" >> $LOG_FILE
	fi
	rm -r "$RESTORE_DIR" && echo "Extraction folder $RESTORE_DIR has been cleaned up" >> $LOG_FILE || echo "Extraction folder $RESTORE_DIR has NOT been cleaned up" >> $LOG_FILE
}

# ****************************************************************************************************
# Finish functions
# ****************************************************************************************************

function EXFIL_TO_CLOUD_C2() {
	if [ "$EXFIL_TO_CLOUD_C2" = "true" ]; then
		if [[ $(pgrep cc-client) ]]; then
			LOG_FILE_DESC="$BACKUP_FILENAME-restore-log"
			C2EXFIL STRING $LOG_FILE $LOG_FILE_DESC && echo "Exfiltration of $LOG_FILE to Cloud C2 has passed" >> $LOG_FILE || echo "Exfiltration of $LOG_FILE to Cloud C2 has failed" >> $LOG_FILE
		else
			echo "Exfiltration of $LOOT_FILE to Cloud C2 has failed, CC-CLIENT seems not to be running" >> $LOG_FILE
		fi
	fi
	return
}

function EXFIL_TO_SCP() {
	if [ "$EXFIL_TO_SCP" = "true" ]; then
		scp "$LOG_FILE" "$RESTORE_DESTINATION_USER@$RESTORE_DESTINATION_HOST:$RESTORE_DESTINATION_DIR_ROOT" && echo "Exfiltration of $LOG_FILE to $BACKUP_DESTINATION_HOST:$BACKUP_DESTINATION_DIR_ROOT/ has passed" >> $LOG_FILE || echo "Exfiltration of $LOG_FILE to $BACKUP_DESTINATION_HOST:$BACKUP_DESTINATION_DIR_ROOT/ has failed" >> $LOG_FILE
	fi
	return
}

function RESTORE_COMPLETED_NOTIFICATION() {
	if [ "$NOTIFY_PUSHOVER" = "true" ]; then
		curl -s --form-string token="$PUSHOVER_APPLICATION_TOKEN" --form-string user="$PUSHOVER_USER_TOKEN" --form-string priority="$PUSHOVER_PRIORITY" --form-string device="$PUSHOVER_DEVICE" --form-string title="SharkJack restore completed message" --form-string message="Restore identifier: $BACKUP_FILENAME, Complete restore took $SECONDS seconds" $PUSHOVER_API_POST_URL > /dev/null && echo "Restore completed notification has been sent to Pushover" >> $LOG_FILE || echo "Restore completed notification has NOT been sent to Pushover as something went wrong" >> $LOG_FILE
	fi
	return
}

# ****************************************************************************************************
# Execute payload
# ****************************************************************************************************

# Setup
LED SETUP
CHECK_INPUT_PARAM $1					# Checks whether given paramerter is an existing zip file
CREATE_RESTORE_FOLDER					# Checks whether restore folder exists and creates or empties if required
INITIALIZE_LOG_FILE					# Initialize the log file
RESTORE_STARTED_NOTIFICATION
START_CLOUD_C2_CLIENT

# Restore
LED ATTACK
INSTALL_PACKAGES
RESTORE_DATA $1

# Finish
LED STAGE2
echo "Free diskspace after actions: $(df -h | grep overlayfs | awk {'print $4'})" >> $LOG_FILE
echo "Restore script took $SECONDS seconds" >> $LOG_FILE
EXFIL_TO_CLOUD_C2
EXFIL_TO_SCP
RESTORE_COMPLETED_NOTIFICATION
sync							# Sync filesystem in order to prevent data loss 

# ****************************************************************************************************
# Prevent logging after this line!
# ****************************************************************************************************

LED FINISH

echo
cat $LOG_FILE
