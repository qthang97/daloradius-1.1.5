#!/bin/bash
SCRIPT_FOLDER_PATH="/home/thangnq5/backup_mariadb/scripts"

bash "$SCRIPT_FOLDER_PATH/backup-daloradius.sh"
sleep 10
bash "$SCRIPT_FOLDER_PATH/autoremove-backup-files.sh"
sleep 10
bash "$SCRIPT_FOLDER_PATH/mount-shared-drive-then-copy-file.sh"