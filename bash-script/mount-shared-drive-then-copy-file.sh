#!/bin/sh

# ================= CONFIGURATION =================
IP_SRV="192.168.20.253"
USERNAME="admin"
PASSWORD="Hcm@1234"
SRC_PATH="/home/thangnq5/backup_mariadb/bk/"
DES_PATH="/home/thangnq5/backup_mariadb/folder_share/"
FOLDER_SHARE_SRC_PATH="//${IP_SRV}/Share/Thangnq5/Radius_bk"
LOG_FILE="rsync.log"
# =================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log() {
    LOG_DIR="${SCRIPT_DIR}/logs"
    [ ! -d "$LOG_DIR" ] && mkdir -p "$LOG_DIR"
    echo "$(date +"%Y-%m-%d %H:%M:%S") : $1"
    echo "$(date +"%Y-%m-%d %H:%M:%S") : $1" >> "$LOG_DIR/$LOG_FILE"
}

fun_MountFolder() {

  if [ ! -d "$DES_PATH" ]; then
    mkdir -p "$DES_PATH"
    log "Created directory: $DES_PATH"
  fi

  # Kiểm tra mount đúng mountpoint
  if mountpoint -q "$DES_PATH"; then
    log "Folder share already mounted."
    return 0
  fi

  log "Mounting share folder..."

  mount -t cifs "$FOLDER_SHARE_SRC_PATH" "$DES_PATH" \
    -o username="$USERNAME",password="$PASSWORD",uid=$(id -u),gid=$(id -g),vers=3.0

  if [ $? -eq 0 ]; then
    log "Mount success."
    return 0
  else
    log "Mount FAILED!"
    return 1
  fi
}

fun_RsyncBackupFile() {

  if ! mountpoint -q "$DES_PATH"; then
    fun_MountFolder
    log "Rsync FAILED - Share not mounted."

    return 1
  fi

  log "Rsync started..."

  rsync -az --inplace --partial --delete "$SRC_PATH" "$DES_PATH"

  if [ $? -eq 0 ]; then
    log "Rsync success."
    return 0
  else
    log "Rsync FAILED!"
    return 1
  fi
}

# ================= MAIN PROCESS =================
fun_MountFolder
fun_RsyncBackupFile
