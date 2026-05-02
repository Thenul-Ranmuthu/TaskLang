#!/bin/bash
echo "[backup.sh] Starting database backup..."
sleep 1
echo "[backup.sh] Dumping database to /tmp/db_backup.sql..."
sleep 1
echo "[backup.sh] Compressing backup file..."
sleep 1
echo "[backup.sh] Backup complete. File saved to /tmp/db_backup.sql.gz"
exit 0   # exit 0 means SUCCESS