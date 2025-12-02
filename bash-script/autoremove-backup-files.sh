#!/bin/bash

# ================= CONFIGURATION (EDIT THIS PART) =================
PATH_BACKUP="/home/thangnq5/backup_mariadb/bk/"
NUM_FILE_WANT_KEEP=6
LOG_FILE="autoremove-old-backup-files.log"
# ====================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log() {
    LOG_DIR="${SCRIPT_DIR}/logs"
    [ ! -d "$LOG_DIR" ] && mkdir -p "$LOG_DIR"
    echo "$(date +"%Y-%m-%d %H:%M:%S") : $1"
    echo "$(date +"%Y-%m-%d %H:%M:%S") : $1" >> "$LOG_DIR/$LOG_FILE"
}

if [ ! -d "$PATH_BACKUP" ]; then
  log "Error - Directory $PATH_BACKUP does not exist."
  exit 1
fi

# Count Files (only file)
NUM_FILES=$(find "$PATH_BACKUP" -maxdepth 1 -type f | wc -l)
log "$PATH_BACKUP has $NUM_FILES files."

# IF num file greate than num file want keep
if [ "$NUM_FILES" -gt "$NUM_FILE_WANT_KEEP" ]; then

  NUM_TO_DELETE=$((NUM_FILES - NUM_FILE_WANT_KEEP))
  log "Need to delete $NUM_TO_DELETE old file(s)."

  # Find oldest file (only file, skip folder)
  find "$PATH_BACKUP" -maxdepth 1 -type f -printf "%p\n" |
    sort -n |
    head -n "$NUM_TO_DELETE" |
    while read -r filepath; do

      # Remove file
      if rm -f "$filepath"; then
        log "Deleted: $filepath"
      else
        log "ERROR deleting: $filepath"
      fi
    done
fi
