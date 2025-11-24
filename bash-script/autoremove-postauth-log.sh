#!/bin/bash

# ================= CONFIGURATION (EDIT THIS PART) =================
CONTAINER_NAME="e8180a2c50bb" # Docker container name
DB_USER="radius"              # Database user
DB_PASS="RadiusPass"          # Database password
DB_NAME="radiusdb"            # Database name
TABLE_NAME="radpostauth"      # Table to delete from
DATE_COLUMN="authdate"        # Date column
LOG_FILE="/home/thangnq5/backup_mariadb/scripts/logs/remove_postauth.log"
NUM_YEAR_WANT_KEEP=0
# =================================================================

log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") : $1"
    echo "$(date +"%Y-%m-%d %H:%M:%S") : $1" >> "$LOG_FILE"
}

CURRENT_YEAR=$(date +%Y)
PREVIOUS_YEAR=$((CURRENT_YEAR - NUM_YEAR_WANT_KEEP))
TARGET_DATE="${PREVIOUS_YEAR}-01-01"

log "Cut-off date for deletion: $TARGET_DATE"

SQL_QUERY="DELETE FROM ${TABLE_NAME} WHERE ${DATE_COLUMN} < '${TARGET_DATE}'; SELECT ROW_COUNT() AS Deleted_rows_count;"

log "SQL Query: $SQL_QUERY"

# Execute SQL and capture output
docker exec -i "$CONTAINER_NAME" sh -c "mysql -u'$DB_USER' -p'$DB_PASS' '$DB_NAME' -e \"$SQL_QUERY\""

DELETED_COUNT=$(
  docker exec -i "$CONTAINER_NAME" sh -c "mysql --skip-column-names -u'$DB_USER' -p'$DB_PASS' '$DB_NAME' -e \"SELECT ROW_COUNT();\""
)

# Log result
if [ -z "$DELETED_COUNT" ]; then
 log "ERROR executing SQL: $DELETED_COUNT"
else
  log "SQL executed successfully."
  log "MySQL Output: $DELETED_COUNT"
fi

log "SQL OPTIMIZE"
docker exec -i "$CONTAINER_NAME" sh -c "mysql -u'$DB_USER' -p'$DB_PASS' '$DB_NAME' -e \"OPTIMIZE TABLE radpostauth;\""

log "Execution finished."
