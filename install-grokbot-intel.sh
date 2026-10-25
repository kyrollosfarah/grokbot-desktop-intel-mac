#!/bin/bash
# Install the official, signed Intel Grok Bot app. No package managers required.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/lib/common.sh"

usage() {
  cat <<'HELP'
Usage: bash install-grokbot-intel.sh [options]
  --dmg PATH       Use an existing official disk image instead of downloading.
  --app-dir PATH   Absolute installation directory (default: /Applications).
  --no-open        Install without launching the app.
  --verify-only    Download/mount/verify the app without installing or launching.
  --help          Show this help.
The default fetches the current official Intel release. Existing app copies are
backed up before replacement. Quit Grok Bot before installing or updating.
HELP
}

APP_DIR=/Applications
DMG_INPUT=''
LAUNCH=true
VERIFY_ONLY=false
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dmg|--app-dir)
      [ "$#" -ge 2 ] || fail "Missing value for $1"
      if [ "$1" = --dmg ]; then DMG_INPUT="$2"; else APP_DIR="$2"; fi
      shift 2 ;;
    --no-open) LAUNCH=false; shift ;;
    --verify-only) VERIFY_ONLY=true; shift ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; fail "Unknown option: $1" ;;
  esac
done

require_intel_mac
version_at_least "$(sw_vers -productVersion)" 12.0 || fail 'macOS 12 or later is required by the verified release.'
case "$APP_DIR" in /*) ;; *) fail '--app-dir must be an absolute path.' ;; esac
APP_DIR="${APP_DIR%/}"
[ -n "$APP_DIR" ] || fail 'Do not install in the filesystem root.'
DEST="$APP_DIR/Grok Bot.app"
if ! $VERIFY_ONLY; then
  if app_is_running; then fail 'Quit Grok Bot (Command-Q), then run this installer again.'; fi
  [ ! -L "$DEST" ] || fail "Refusing to replace a symlink: $DEST"
fi

GROK_TMP=$(mktemp -d "${TMPDIR:-/tmp}/grokbot-install.XXXXXX")
GROK_TMP=$(cd "$GROK_TMP" && pwd -P)
MOUNT="$GROK_TMP/mounted"
MOUNT_REQUESTED=false
STAGE=''
BACKUP=''
MOVED_OLD=false
PLACED_NEW=false
SUCCESS=false

cleanup() {
  local result=$?
  trap - EXIT INT TERM HUP
  if ! $SUCCESS; then
    if $PLACED_NEW && [ -d "$DEST" ] && [ -n "$STAGE" ]; then
      mv "$DEST" "$STAGE/Failed Grok Bot.app" || true
    fi
    if $MOVED_OLD && [ -n "$BACKUP" ] && [ -d "$BACKUP/Grok Bot.app" ]; then
      if [ ! -e "$DEST" ]; then
        mv "$BACKUP/Grok Bot.app" "$DEST" || printf 'Restore the previous app from %s\n' "$BACKUP" >&2
        rmdir "$BACKUP" 2>/dev/null || true
      else
        printf 'Previous app preserved at %s\n' "$BACKUP" >&2
      fi
    fi
  fi
  if $MOUNT_REQUESTED; then
    if ! hdiutil detach "$MOUNT" -quiet; then
      printf 'Installer volume still mounted at %s; eject it in Finder.\n' "$MOUNT" >&2
      [ -z "$STAGE" ] || rm -rf "$STAGE"
      exit "$result"
    fi
  fi
  [ -z "$STAGE" ] || rm -rf "$STAGE"
  rm -rf "$GROK_TMP"
  exit "$result"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

EXPECTED_VERSION=''
if [ -n "$DMG_INPUT" ]; then
  [ -f "$DMG_INPUT" ] || fail "Disk image not found: $DMG_INPUT"
  DMG_INPUT=$(cd "$(dirname "$DMG_INPUT")" && pwd)/$(basename "$DMG_INPUT")
  DMG="$DMG_INPUT"
else
  printf 'Fetching the current official Intel release…\n'
  curl --fail --show-error --location --proto '=https' --proto-redir '=https' \
    --connect-timeout 30 --max-time 60 --retry 2 \
    https://api2.cursor.sh/updates/api/download/stable/darwin-x64/sand -o "$GROK_TMP/release.json"
  DOWNLOAD_URL=$(plutil -extract downloadUrl raw -o - "$GROK_TMP/release.json")
  EXPECTED_VERSION=$(plutil -extract version raw -o - "$GROK_TMP/release.json")
  [[ "$EXPECTED_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail 'Unexpected version in the release feed.'
  [ "$DOWNLOAD_URL" = "https://downloads.cursor.com/grokbot/stable/darwin-x64/$EXPECTED_VERSION/Grok_Bot_${EXPECTED_VERSION}_x64.dmg" ] ||
    fail 'The official download URL format changed. Review the feed and update this script.'
  DMG="$GROK_TMP/Grok_Bot_x64.dmg"
  curl --fail --show-error --location --proto '=https' --proto-redir '=https' \
    --connect-timeout 30 --max-time 900 --retry 2 "$DOWNLOAD_URL" -o "$DMG"
fi

printf 'Disk image checksum (for your records):\n'
shasum -a 256 "$DMG"
mkdir "$MOUNT"
MOUNT_REQUESTED=true
hdiutil attach -readonly -nobrowse -mountpoint "$MOUNT" "$DMG"
SOURCE_APP="$MOUNT/Grok Bot.app"
verify_app "$SOURCE_APP"
if [ -n "$EXPECTED_VERSION" ]; then
  [ "$(plist_value "$SOURCE_APP" CFBundleShortVersionString)" = "$EXPECTED_VERSION" ] || fail 'The app version does not match the release feed.'
fi
if $VERIFY_ONLY; then
  SUCCESS=true
  printf 'Verification complete. No app was installed or launched.\n'
  exit 0
fi

mkdir -p "$APP_DIR" || fail "Cannot create $APP_DIR. Try --app-dir \"\$HOME/Applications\"."
[ -w "$APP_DIR" ] || fail "Cannot write to $APP_DIR. Try --app-dir \"\$HOME/Applications\" or use Finder."
# Copy into a fresh sibling directory. An interruption cannot contaminate the live app.
STAGE=$(mktemp -d "$APP_DIR/.grokbot-stage.XXXXXX")
ditto "$SOURCE_APP" "$STAGE/Grok Bot.app"
verify_app "$STAGE/Grok Bot.app"
if app_is_running; then fail 'Grok Bot started during installation. Quit it and run the installer again.'; fi
[ ! -L "$DEST" ] || fail "Refusing to replace a symlink: $DEST"
if [ -e "$DEST" ]; then
  [ -d "$DEST" ] || fail "An unexpected file exists at $DEST"
  BACKUP=$(mktemp -d "$APP_DIR/Grok Bot Backup.XXXXXX")
  MOVED_OLD=true
  mv "$DEST" "$BACKUP/Grok Bot.app"
fi
PLACED_NEW=true
mv "$STAGE/Grok Bot.app" "$DEST"
verify_app "$DEST"
SUCCESS=true
printf '\nInstalled: %s\n' "$DEST"
[ -z "$BACKUP" ] || printf 'Previous app saved at: %s/Grok Bot.app\n' "$BACKUP"
if $LAUNCH; then
  open "$DEST" || printf 'Installation succeeded. Open Grok Bot from Finder.\n' >&2
fi
printf 'Next: sign in inside Grok Bot.\n'
