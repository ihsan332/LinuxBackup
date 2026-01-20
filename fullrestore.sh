#!/bin/bash
bucketname="my-ubuntu-backups"
bucketdate=$(date +%Y-%m-%d)
timestamp=$(date +%Y%m%d_%H%M%S)
restorepath=(
    "$HOME/Music"
    "$HOME/Downloads"
)
logfile="$HOME/logs/restore_$timestamp.log"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $logfile
}

for folder in ${restorepath[@]}; do
    folder_name=$(basename $folder)
    log_message "Restoring $folder from s3://$bucketname/mainbackup1/$folder_name/"
    
    aws s3 sync "s3://$bucketname/mainbackup1/$folder_name/" $folder >> $logfile 2>&1
    
    if [ $? -eq 0 ]; then
        log_message "Successfully restored $folder"
    else
        log_message "Failed to restore $folder"
    fi
done

log_message "Restore process completed"
