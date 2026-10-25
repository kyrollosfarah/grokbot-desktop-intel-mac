#!/bin/bash
# Fetch the current official Intel app using the same checks and backup procedure.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
exec /bin/bash "$SCRIPT_DIR/install-grokbot-intel.sh" "$@"
