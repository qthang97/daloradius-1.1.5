#/bin/sh

# ================= CONFIGURATION (EDIT THIS PART) =================
CONTAINER_NAME_OR_ID_MOBILE="e8180a2c50bb" # Docker container name mobile
BACKUP_NAME_MOBILE="sql_mobile.sql"        # Backup file name
CONTAINER_NAME_OR_ID_LAPTOP="dca56b3d9764" # Docker container name laptop
BACKUP_NAME_LAPTOP="sql_laptop.sql"        # Backup file name
DB_USER="radius"     # Database user
DB_PASS="RadiusPass" # Database password
DB_NAME="radiusdb"   # Database name
PATH_BACKUP="/home/thangnq5/backup_mariadb/bk/"
LOG_FILE="backup_sql_docker.log"
# ====================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log() {
    LOG_DIR="${SCRIPT_DIR}/logs"
    [ ! -d "$LOG_DIR" ] && mkdir -p "$LOG_DIR"
    echo "$(date +"%Y-%m-%d %H:%M:%S") : $1"
    echo "$(date +"%Y-%m-%d %H:%M:%S") : $1" >> "$LOG_DIR/$LOG_FILE"
}

fun_CreateBackup() {
    # Input params
    container="$1"
    backup_name="$2"

    date_now=$(date +"%Y_%m_%d")
    date_log=$(date +"%Y-%m-%d %H:%M:%S")

    # Determine filename
    if [ -n "$backup_name" ]; then
        file_name="${date_now}_${backup_name}"
    else
        file_name="${date_now}_${container}.sql"
    fi

    full_path="${PATH_BACKUP}${file_name}"

    # Execute mysqldump
    docker exec "$container" /usr/bin/mysqldump -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$full_path"
    status=$?

    # Check mysqldump status
    if [ $status -ne 0 ]; then
        log "Backup $file_name FAILED (mysqldump error)"
        return 1
    fi

    # Check file valid and > 0 bytes
    if [ ! -s "$full_path" ]; then
        log "Backup $file_name FAILED (empty file)"
        return 1
    fi

    chmod 775 "$full_path"
    log "Backup $file_name SUCCESS"
}

# Run backup
fun_CreateBackup "$CONTAINER_NAME_OR_ID_MOBILE" "$BACKUP_NAME_MOBILE"
fun_CreateBackup "$CONTAINER_NAME_OR_ID_LAPTOP" "$BACKUP_NAME_LAPTOP"
