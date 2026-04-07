#!/bin/sh
set -eu

DB_PATH="/database/filebrowser.db"
CFG_PATH="/config/settings.json"

mkdir -p /database /config /srv

# Initialize config file if needed
if [ ! -f "$CFG_PATH" ]; then
  filebrowser config init -c "$CFG_PATH" -d "$DB_PATH"
fi

# Ensure database exists before config set operations
if [ ! -f "$DB_PATH" ]; then
  filebrowser -c "$CFG_PATH" -d "$DB_PATH" --root "${FILEBROWSER_ROOT:-/srv}" --baseURL "${FILEBROWSER_BASEURL:-/files}" --address "${FILEBROWSER_ADDRESS:-0.0.0.0}" --port "${FILEBROWSER_PORT:-80}" --log "${FILEBROWSER_LOG:-stdout}" ${FILEBROWSER_NOAUTH:+--noauth} >/dev/null 2>&1 &
  pid="$!"
  sleep 2
  kill "$pid" >/dev/null 2>&1 || true
fi

# Persist desired config in the DB/config
filebrowser config set   -c "$CFG_PATH"   -d "$DB_PATH"   --address "${FILEBROWSER_ADDRESS:-0.0.0.0}"   --port "${FILEBROWSER_PORT:-80}"   --baseURL "${FILEBROWSER_BASEURL:-/files}"   --root "${FILEBROWSER_ROOT:-/srv}"   --log "${FILEBROWSER_LOG:-stdout}"   --auth.method noauth

exec filebrowser   -c "$CFG_PATH"   -d "$DB_PATH"
