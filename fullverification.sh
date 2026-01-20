#!/bin/bash
bucketname="my-ubuntu-backups"
bucketdate=$(date +%Y-%m-%d)
timestamp=$(date +%Y%m%d_%H%M%S)
verifypath=(
    "$HOME/Music"
    "$HOME/Downloads"
)
logfile="$HOME/logs/verify_$timestamp.log"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $logfile
}

log_message "Starting MD5 verification process"

for folder in ${verifypath[@]}; do
    if [ -d "$folder" ]; then
        folder_name=$(basename $folder)
        log_message "Verifying $folder against s3://$bucketname/mainbackup1/$folder_name/"
        
        mismatch_count=0
        match_count=0
        missing_s3=0
        
        while IFS= read -r -d '' local_file; do
            relative_path="${local_file#$folder/}"
            s3_path="s3://$bucketname/mainbackup1/$folder_name/$relative_path"
            

            local_md5=$(md5sum "$local_file" | awk '{print $1}')
            

            s3_etag=$(aws s3api head-object --bucket "$bucketname" --key "mainbackup1/$folder_name/$relative_path" --query 'ETag' --output text | tr -d '"')
            
            if [ -z "$s3_etag" ]; then
                log_message "MISSING IN S3: $relative_path"
                ((missing_s3++))
            elif [ "$local_md5" == "$s3_etag" ]; then
                log_message "MATCH: $relative_path"
                ((match_count++))
            else
                log_message "MISMATCH: $relative_path (Local: $local_md5, S3: $s3_etag)"
                ((mismatch_count++))
            fi
        done < <(find "$folder" -type f -print0)
        
        log_message "Verification complete for $folder"
        log_message "Matches: $match_count, Mismatches: $mismatch_count, Missing in S3: $missing_s3"
        
    else
        log_message "$folder dosent exist, skipping the folder"
    fi
done

log_message "MD5 verification process completed"
