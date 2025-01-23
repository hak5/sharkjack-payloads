#!/bin/bash
#
# Title:		backup.sh   
# Description:		Backup important data on SharkJack, zip it and optionally exfiltrate
#			Execute with: bash ./backup.sh (e.g. "bash ./backup.sh")
# Author:		Robert Coemans
# Version:		1.0 (20-08-2020)
# Category:		Util
#
# Dependencies: this payload requires you to have the following packages already installed and configured via 'opkg install' (do 'opkg update' first):
# - curl		= E.g. to grab external IP address and to post notifications
# - zip
#
# LED indications (https://docs.hak5.org/hc/en-us/articles/360010554653-LED)
# - Setting up		= Magenta solid [LED SETUP]
# - Backing up		= Yellow single blink [LED ATTACK]
# - Finishing up	= Yellow double blink [LED STAGE2]
# - Finished		= Green very fast blinking followed by solid [LED FINISH]

# ****************************************************************************************************
# Configuration
# ****************************************************************************************************

# Setup toggles
NOTIFY_PUSHOVER=true
START_CLOUD_C2_CLIENT=false

# Finish toggles
EXFIL_TO_CLOUD_C2=true
EXFIL_TO_SCP=false

# Setup variables
BACKUP_DIR_ROOT="/root/backup"
TODAY=$(date +%Y%m%d)
START_TIME=$(date)
BATTERY_STATUS=$(BATTERY)
CLOUD_C2_PROVISION="/etc/device.config"

# Backup variables
BACKUP_FOLDERS=( "/root/payload" "/root/loot" "/usr/share/arp-scan" )		# Add folders to be backed up here!
BACKUP_FILES=( "/etc/device.config" )		# Add files to be backed up here!
BACKUP_DESTINATION_USER="{username}"			# Generate a ssh key (ssh-keygen) on the destination host and copy it (~/.ssh/id_rsa_pub) to the SharkJack (~/.ssh/authorized/keys) in order to bypass password!
BACKUP_DESTINATION_HOST="192.168.10.1"
BACKUP_DESTINATION_DIR_ROOT="/some/destination/folder/for/backup"

# Exfiltrate and notification variables
PUSHOVER_API_POST_URL="https://api.pushover.net/1/messages.json"
PUSHOVER_APPLICATION_TOKEN="{your-application-token}"
PUSHOVER_USER_TOKEN="{your-user-token}"
PUSHOVER_PRIORITY="1"				# send as -2 to generate no notification/alert, -1 to always send as a quiet notification or 1 to display as high-priority and bypass the user's quiet hours!
PUSHOVER_DEVICE="{your-device}"			# Multiple devices may be separated by a comma!

# ****************************************************************************************************
# Setup functions
# ****************************************************************************************************

function CREATE_BACKUP_FOLDER() {
	if [ ! -d $BACKUP_DIR_ROOT ]; then
		mkdir -p $BACKUP_DIR_ROOT > /dev/null
	fi
	if [ "ls $BACKUP_DIR_ROOT -l | grep "^d" | wc -l" = "0" ]; then
		SCAN_COUNT=1
	else
		SCAN_COUNT=$(ls $BACKUP_DIR_ROOT -l | grep "^d" | awk {'print $9'} | sort -n | awk 'END{print}' | awk -F'-' '{print $1}')
		((SCAN_COUNT++))
	fi
	BACKUP_DIR=$BACKUP_DIR_ROOT/$SCAN_COUNT-$TODAY-SharkJack-backup
	mkdir $BACKUP_DIR > /dev/null
	return
}

function INITIALIZE_LOG_FILE() {
	LOG_FILE=$BACKUP_DIR_ROOT/$SCAN_COUNT-$TODAY-SharkJack-backup.log
	touch $LOG_FILE
	echo "****************************************************************************************************" >> $LOG_FILE
	echo "Backup executed at: $START_TIME" >> $LOG_FILE
	echo "SharkJack battery status: $BATTERY_STATUS" >> $LOG_FILE
	echo "****************************************************************************************************" >> $LOG_FILE
	echo >> $LOG_FILE
	echo "Free diskspace before actions: $(df -h | grep overlayfs | awk {'print $4'})" >> $LOG_FILE
	echo "Backup directory has been created: $BACKUP_DIR" >> $LOG_FILE
	return
}

function BACKUP_STARTED_NOTIFICATION() {
	if [ "$NOTIFY_PUSHOVER" = "true" ]; then
		curl -s --form-string token="$PUSHOVER_APPLICATION_TOKEN" --form-string user="$PUSHOVER_USER_TOKEN" --form-string priority="$PUSHOVER_PRIORITY" --form-string device="$PUSHOVER_DEVICE" --form-string title="SharkJack backup started on date: $(date '+%d-%m-%Y'), time: $(date '+%H:%M')  $(date '+%Z %z')" --form-string message="Backup identifier: $SCAN_COUNT-$TODAY" $PUSHOVER_API_POST_URL > /dev/null && echo "Backup started notification has been sent to Pushover" >> $LOG_FILE || echo "Backup started notification has NOT been sent to Pushover as something went wrong" >> $LOG_FILE
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
# Backup functions
# ****************************************************************************************************

function BACKUP_FOLDERS() {
	for BACKUP_FOLDER in ${BACKUP_FOLDERS[@]}; do
		mkdir -p $BACKUP_DIR/$BACKUP_FOLDER
		cp -r $BACKUP_FOLDER/* $BACKUP_DIR/$BACKUP_FOLDER
		echo "Folder $BACKUP_FOLDER has been copied to backup destination" >> $LOG_FILE
	done
	return
}

function BACKUP_FILES() {
	for BACKUP_FILE in ${BACKUP_FILES[@]}; do
		mkdir -p $(dirname $BACKUP_DIR/$BACKUP_FILE)
		cp $BACKUP_FILE $BACKUP_DIR/$BACKUP_FILE
		echo "File $BACKUP_FILE has been copied to backup destination" >> $LOG_FILE
	done
	return
}

function CREATE_ZIP_FILE() {
	# Including removing backup files and moving zip file and log file to backup folder
	ZIP_FILE=$BACKUP_DIR_ROOT/$SCAN_COUNT-$TODAY-SharkJack-backup.zip
	cd $BACKUP_DIR
	zip -r $ZIP_FILE ./* > /dev/null
	echo "Backup has been zipped into the file $ZIP_FILE" >> $LOG_FILE
	rm -rf $BACKUP_DIR/*
	echo "Contents from folder $BACKUP_DIR has been removed" >> $LOG_FILE
	mv $LOG_FILE $BACKUP_DIR/
	LOG_FILE=$BACKUP_DIR/$SCAN_COUNT-$TODAY-SharkJack-backup.log
	echo "Log file has been moved to backup destination" >> $LOG_FILE
	mv $ZIP_FILE $BACKUP_DIR/
	ZIP_FILE=$BACKUP_DIR/$SCAN_COUNT-$TODAY-SharkJack-backup.zip
	echo "Zip file has been moved to backup destination" >> $LOG_FILE
	return
}

# ****************************************************************************************************
# Finish functions
# ****************************************************************************************************

function EXFIL_TO_CLOUD_C2() {
	if [ "$EXFIL_TO_CLOUD_C2" = "true" ]; then
		if [[ $(pgrep cc-client) ]]; then
			LOG_FILE_DESC="$SCAN_COUNT-$TODAY-SharkJack-backup-log"
			C2EXFIL STRING $LOG_FILE $LOG_FILE_DESC && echo "Exfiltration of $LOG_FILE to Cloud C2 has passed" >> $LOG_FILE || echo "Exfiltration of $LOG_FILE to Cloud C2 has failed" >> $LOG_FILE
			ZIP_FILE_DESC="$SCAN_COUNT-$TODAY-SharkJack-backup-zip"
			C2EXFIL $ZIP_FILE $ZIP_FILE_DESC && echo "Exfiltration of $ZIP_FILE to Cloud C2 has passed" >> $LOG_FILE || echo "Exfiltration of $ZIP_FILE to Cloud C2 has failed" >> $LOG_FILE
		else
			echo "Exfiltration of $LOOT_FILE to Cloud C2 has failed, CC-CLIENT seems not to be running" >> $LOG_FILE
		fi
	fi
	return
}

function EXFIL_TO_SCP() {
	if [ "$EXFIL_TO_SCP" = "true" ]; then
		scp -pr "$BACKUP_DIR" "$BACKUP_DESTINATION_USER@$BACKUP_DESTINATION_HOST:$BACKUP_DESTINATION_DIR_ROOT/" && echo "Backup has been copied to $BACKUP_DESTINATION_HOST:$BACKUP_DESTINATION_DIR_ROOT/" >> $LOG_FILE || echo "Backup failed to copy to $BACKUP_DESTINATION_HOST:$BACKUP_DESTINATION_DIR_ROOT/" >> $LOG_FILE
	fi
	return
}

function BACKUP_COMPLETED_NOTIFICATION() {
	if [ "$NOTIFY_PUSHOVER" = "true" ]; then
		curl -s --form-string token="$PUSHOVER_APPLICATION_TOKEN" --form-string user="$PUSHOVER_USER_TOKEN" --form-string priority="$PUSHOVER_PRIORITY" --form-string device="$PUSHOVER_DEVICE" --form-string title="SharkJack backup completed message" --form-string message="Backup identifier: $SCAN_COUNT-$TODAY, Complete backup took $SECONDS seconds" $PUSHOVER_API_POST_URL > /dev/null && echo "Backup completed notification has been sent to Pushover" >> $LOG_FILE || echo "Backup completed notification has NOT been sent to Pushover as something went wrong" >> $LOG_FILE
	fi
	return
}

# ****************************************************************************************************
# Execute payload
# ****************************************************************************************************

# Setup
LED SETUP
CREATE_BACKUP_FOLDER					# Checks backup folder with highest index number in backup root folder and creates the next backup folder for current scan
INITIALIZE_LOG_FILE					# Initialize the log file
BACKUP_STARTED_NOTIFICATION
START_CLOUD_C2_CLIENT

# Backup
LED ATTACK
BACKUP_FOLDERS
BACKUP_FILES
CREATE_ZIP_FILE

# Finish
LED STAGE2
echo "Free diskspace after actions: $(df -h | grep overlayfs | awk {'print $4'})" >> $LOG_FILE
echo "Backup script took $SECONDS seconds" >> $LOG_FILE
EXFIL_TO_CLOUD_C2
EXFIL_TO_SCP
BACKUP_COMPLETED_NOTIFICATION
sync							# Sync filesystem in order to prevent data loss 

# ****************************************************************************************************
# Prevent logging after this line!
# ****************************************************************************************************

LED FINISH

echo
cat $LOG_FILE
