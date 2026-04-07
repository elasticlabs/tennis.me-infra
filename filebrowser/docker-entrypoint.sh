#!/bin/sh
set -eu

DB_PATH="/database/filebrowser.db"
CFG_PATH="/config/settings.json"

mkdir -p /database /config /srv

if [ ! -f "$CFG_PATH" ]; then
  filebrowser config init -c "$CFG_PATH" -d "$DB_PATH"
fi

filebrowser config set   -c "$CFG_PATH"   -d "$DB_PATH"   --address "${FILEBROWSER_ADDRESS:-0.0.0.0}"   --port "${FILEBROWSER_PORT:-80}"   --baseURL "${FILEBROWSER_BASEURL:-/files}"   --root "${FILEBROWSER_ROOT:-/srv}"   --log "${FILEBROWSER_LOG:-stdout}"   --auth.method noauth

exec filebrowser   -c "$CFG_PATH"   -d "$DB_PATH"
