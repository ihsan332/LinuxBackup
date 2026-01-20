#!/bin/bash
bucketname="my-ubuntu-backups"
bucketdate=$(date +%Y-%m-%d)
timestamp=$(date +%Y%m%d_%H%M%S)

backuppath=(
    "$HOME/Music"
    "$HOME/Downloads"
)

logfile="$HOME/logs/backup_$timestamp.log"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $logfile
}


for folder in ${backuppath[@]}; do
    if [ -d $folder ]; then
        folder_name=$(basename $folder)
        log_message "Backing up $folder to s3://$bucketname/mainbackup1/$folder_name/"
        
        aws s3 sync $folder "s3://$bucketname/mainbackup1/$folder_name/" --delete >> $logfile 2>&1
        
        if [ $? -eq 0 ]; then
            log_message "Successfully backed up $folder"
        else
            log_message "Failed to backup $folder"
        fi
    else
        log_message "$folder dosent exist, skipping the folder"
    fi
done

log_message "Full backup completed successfully!"
log_message "Backup location: s3://$bucketname/$bucketdate/"
