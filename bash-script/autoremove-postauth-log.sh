#!/bin/bash

# ================= CONFIGURATION (EDIT THIS PART) =================
CONTAINER_NAME="e8180a2c50bb" # Docker container name
DB_USER="radius"              # Database user
DB_PASS="RadiusPass"          # Database password
DB_NAME="radiusdb"            # Database name
TABLE_NAME="radpostauth"      # Table to delete from
DATE_COLUMN="authdate"        # Date column
LOG_FILE="/home/thangnq5/backup_mariadb/scripts/logs/remove_postauth.log"
NUM_YEAR_WANT_KEEP=1
# =================================================================

log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") : $1"
    echo "$(date +"%Y-%m-%d %H:%M:%S") : $1" >> "$LOG_FILE"
}

cleanup_mysql_data() {
    local CONTAINER_TARGET="$1"
    local YEARS_KEEP="${2:-$NUM_YEAR_WANT_KEEP}" # Nếu không truyền $2, dùng biến global

    # 1. Kiểm tra tham số
    if [ -z "$CONTAINER_TARGET" ]; then
        log "ERROR: Vui lòng cung cấp Container Name hoặc ID."
        return 1
    fi

    # 2. Tính toán ngày
    local CURRENT_YEAR=$(date +%Y)
    local PREVIOUS_YEAR=$((CURRENT_YEAR - YEARS_KEEP))
    local TARGET_DATE="${PREVIOUS_YEAR}-01-01"

    log "------------------------------------------------"
    log "Target Container: $CONTAINER_TARGET"
    log "Cut-off date for deletion: $TARGET_DATE"

    # 3. Chuẩn bị câu lệnh SQL
    # Lưu ý: Chạy DELETE và SELECT ROW_COUNT() trong cùng 1 câu lệnh để lấy kết quả chính xác
    local SQL_CLEANUP="DELETE FROM ${TABLE_NAME} WHERE ${DATE_COLUMN} < '${TARGET_DATE}'; SELECT ROW_COUNT();"

    log "Executing Cleanup SQL..."

    # 4. Thực thi và lấy số dòng đã xóa
    # Dùng cờ -N (Skip column headers) để chỉ lấy số
    # Dùng cờ -s (Silent) để bớt ồn
    local DELETED_COUNT
    DELETED_COUNT=$(docker exec -i "$CONTAINER_TARGET" sh -c "mysql -N -s -u'$DB_USER' -p'$DB_PASS' '$DB_NAME' -e \"$SQL_CLEANUP\"")
    local EXIT_CODE=$?

    # 5. Kiểm tra kết quả
    if [ $EXIT_CODE -ne 0 ]; then
        log "ERROR executing SQL on container '$CONTAINER_TARGET'."
        return 1
    else
        # Nếu output rỗng, gán là 0
        if [ -z "$DELETED_COUNT" ]; then DELETED_COUNT=0; fi
        log "SQL executed successfully."
        log "Deleted Rows: $DELETED_COUNT"
    fi

    # 6. Optimize Table (Chạy riêng để an toàn)
    log "Running OPTIMIZE TABLE..."
    docker exec -i "$CONTAINER_TARGET" sh -c "mysql -u'$DB_USER' -p'$DB_PASS' '$DB_NAME' -e \"OPTIMIZE TABLE ${TABLE_NAME};\"" > /dev/null 2>&1

    log "Execution finished for $CONTAINER_TARGET."
    log "------------------------------------------------"
}

# --- CÁCH SỬ DỤNG ---

# Cách 1: Truyền tên container (Dùng biến NUM_YEAR_WANT_KEEP global)
cleanup_mysql_data "$CONTAINER_NAME"

# Cách 2: Truyền cả tên container và số năm muốn giữ (ghi đè global)
# cleanup_mysql_data "mysql_container_id_xyz" 5
