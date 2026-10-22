#!/usr/bin/env bash
# Adds the launcher to the application menu (~/.local/share/applications) for this checkout.
set -euo pipefail
here=$(cd -- "$(dirname -- "$0")" && pwd)

python3 "$here/uncharted_launcher.py" --add-to-menu
