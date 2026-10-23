#!/usr/bin/env bash
set -e

APP_DIR="/opt/uncharted"
export PATH="${APP_DIR}/bin:${APP_DIR}/out:${PATH}"
export LD_LIBRARY_PATH="${APP_DIR}/lib:${APP_DIR}/out/gpu:${LD_LIBRARY_PATH:-}"
export BB_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/uncharted"
mkdir -p "$BB_DATA_DIR"

cd "$APP_DIR"
exec python3 "${APP_DIR}/launcher/uncharted_launcher.py" "$@"
