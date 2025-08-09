# Droplet Backup Setup Guide

## 1️⃣ Create password file for Postgres
Store the DB password securely so scripts/cron won’t prompt you:
```bash
echo "localhost:5432:todo_db:kimlong_api:11112222" > /root/.pgpass
chmod 600 /root/.pgpass
```

---

## 2️⃣ Create backup storage folder
```bash
mkdir -p /opt/backup
mkdir -p /var/backups/dropbet
```

---

## 3️⃣ Create the backup script
Path: `/opt/backup/backup.sh`

```bash
#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

# ===== CONFIG =====
APP_DIRS=(
  "/var/www/api-helloworld"
  "/var/www/html"
  "/var/www/nextjs-helloworld"
)

BACKUP_DIR="/var/backups/dropbet"
RETENTION_DAILY=7
RETENTION_WEEKLY=4

# Postgres connection (password from /root/.pgpass)
PGHOST="localhost"
PGPORT="5432"
PGUSER="kimlong_api"
PGDATABASE="todo_db"
# ==================

NOW="$(date +'%Y-%m-%d_%H-%M-%S')"
TYPE="${1:-daily}"   # daily | weekly
DEST_DIR="${BACKUP_DIR}/${TYPE}/${NOW}"
mkdir -p "$DEST_DIR"

log() { echo "[$(date +'%F %T')] $*"; }

# ---- App backups ----
for DIR in "${APP_DIRS[@]}"; do
  if [[ -d "$DIR" ]]; then
    NAME="$(basename "$DIR" | tr '/' '_')"
    log "Backing up app dir: $DIR -> ${NAME}.tar.gz"
    tar -czf "${DEST_DIR}/${NAME}.tar.gz"       --exclude=node_modules       --exclude=.git       -C "$(dirname "$DIR")" "$(basename "$DIR")"
  else
    log "WARN: app dir not found: $DIR"
  fi
done

# ---- DB backup ----
log "Dumping PostgreSQL database $PGDATABASE..."
# Custom-format dump
pg_dump -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -F c -d "$PGDATABASE" -f "${DEST_DIR}/db.dump"
# Plain SQL format
pg_dump -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -F p -d "$PGDATABASE" | gzip > "${DEST_DIR}/db.sql.gz"

# ---- Manifest ----
cat > "${DEST_DIR}/MANIFEST.txt" <<MANI
timestamp=${NOW}
type=${TYPE}
hostname=$(hostname -f 2>/dev/null || hostname)
apps=${APP_DIRS[*]}
db=${PGDATABASE}
MANI

# ---- Retention prune ----
KEEP=$RETENTION_DAILY
[[ "$TYPE" == "weekly" ]] && KEEP=$RETENTION_WEEKLY
log "Pruning to keep last $KEEP ${TYPE} backups..."
if compgen -G "${BACKUP_DIR}/${TYPE}/*" > /dev/null; then
  ls -1dt "${BACKUP_DIR}/${TYPE}/"* 2>/dev/null | tail -n +$((KEEP+1)) | xargs -r rm -rf --
fi

log "Backup complete: $DEST_DIR"
```

Make it executable:
```bash
chmod +x /opt/backup/backup.sh
```

---

## 4️⃣ Test the script
```bash
/opt/backup/backup.sh daily
```
Check result:
```bash
ls -l /var/backups/dropbet/daily
```

---

## 5️⃣ Schedule automatic backups with cron
Edit root crontab:
```bash
crontab -e
```
choose 1 and Add:
```
0 2 * * * /opt/backup/backup.sh daily >> /var/log/backup.log 2>&1
0 3 * * 0 /opt/backup/backup.sh weekly >> /var/log/backup.log 2>&1
```

---

## 6️⃣ Download backups to local machine
From your PC:
```powershell
scp -r root@YOUR_SERVER_IP:/var/backups/dropbet/daily/2025-08-09_03-33-30 .
```

---

## 7️⃣ Restore instructions
- From `.dump`:
```bash
pg_restore -h localhost -U kimlong_api -d todo_db /path/to/db.dump
```
- From `.sql.gz`:
```bash
gunzip -c /path/to/db.sql.gz | psql -h localhost -U kimlong_api -d todo_db
```
- App files:
```bash
tar -xzf app-name.tar.gz -C /target/path
```

---

## 8️⃣ Backup retention
- **Daily:** keep last **7**
- **Weekly:** keep last **4**
