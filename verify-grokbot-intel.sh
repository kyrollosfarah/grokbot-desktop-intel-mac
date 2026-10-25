#!/bin/bash
# Read-only verification of an installed app.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/lib/common.sh"
case "${1:-}" in
  --help|-h) printf 'Usage: bash verify-grokbot-intel.sh [absolute path to Grok Bot.app]\n'; exit 0 ;;
esac
[ "$#" -le 1 ] || fail 'Supply only the app path, in quotes.'
require_intel_mac
verify_app "${1:-/Applications/Grok Bot.app}"
