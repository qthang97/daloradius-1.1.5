#!/bin/bash

# ================= CONFIGURATION (EDIT THIS PART) =================
DB_USER="radius"              # Database user
DB_PASS="RadiusPass"          # Database password
DB_NAME="radiusdb"            # Database name
TABLE_NAME="radpostauth"      # Table to delete from
DATE_COLUMN="authdate"        # Date column
LOG_FILE="remove_postauth.log"
NUM_YEAR_WANT_KEEP=1
# =================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log() {
    LOG_DIR="${SCRIPT_DIR}/logs"
    [ ! -d "$LOG_DIR" ] && mkdir -p "$LOG_DIR"
    echo "$(date +"%Y-%m-%d %H:%M:%S") : $1"
    echo "$(date +"%Y-%m-%d %H:%M:%S") : $1" >> "$LOG_DIR/$LOG_FILE"
}

cleanup_mysql_data() {
    local CONTAINER_TARGET="$1"
    local YEARS_KEEP="${2:-$NUM_YEAR_WANT_KEEP}" # If want change num want keep with special container, if not input us global

    # Check container
    if [ -z "$CONTAINER_TARGET" ]; then
        log "ERROR: Cannot find Container ID or Name"
        return 1
    fi

    # Caculate date
    local CURRENT_YEAR=$(date +%Y)
    local PREVIOUS_YEAR=$((CURRENT_YEAR - YEARS_KEEP))
    local TARGET_DATE="${PREVIOUS_YEAR}-01-01"

    log "------------------------------------------------"
    log "Target Container: $CONTAINER_TARGET"
    log "Cut-off date for deletion: $TARGET_DATE"

    # 3. SQL Query
    SQL_QUERY="DELETE FROM ${TABLE_NAME} WHERE ${DATE_COLUMN} < '${TARGET_DATE}'; SELECT ROW_COUNT() AS Deleted_rows_count;"
    log "SQL Query: $SQL_QUERY" 

    # 4. Excute Query
    # Thêm -N (skip header) and -s (silent - skip border)
    DELETED_COUNT=$(docker exec -i "$CONTAINER_NAME" sh -c "mysql -N -s -u'$DB_USER' -p'$DB_PASS' '$DB_NAME' -e \"$SQL_QUERY\"")
    log "Deleted: $DELETED_COUNT"

    # 5. Optimize Table
    log "Running OPTIMIZE TABLE..."
    docker exec -i "$CONTAINER_TARGET" sh -c "mysql -u'$DB_USER' -p'$DB_PASS' '$DB_NAME' -e \"OPTIMIZE TABLE ${TABLE_NAME};\"" > /dev/null 2>&1

    log "Execution finished for $CONTAINER_TARGET."
    log "------------------------------------------------"
}

# --- How to use ---

CONTAINER_NAME="e8180a2c50bb" # Docker container name
cleanup_mysql_data "$CONTAINER_NAME"
# cleanup_mysql_data "mysql_container_id_xyz" 5
