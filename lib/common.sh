#!/bin/bash
# Shared checks; compatible with the Bash 3.2 included with macOS.

fail() { printf 'Error: %s\n' "$*" >&2; exit 1; }

require_intel_mac() {
  [ "$(uname -s)" = Darwin ] || fail 'This installer requires macOS.'
  [ "$(uname -m)" = x86_64 ] || fail 'Use the Apple silicon download at https://x.ai/bot for this Mac.'
  [ "$(sysctl -in sysctl.proc_translated 2>/dev/null || true)" != 1 ] ||
    fail 'This is an Apple silicon Mac running Rosetta. Use the Apple silicon download.'
}

version_at_least() {
  local actual="$1" required="$2" a b c x y z
  IFS=. read -r a b c <<< "$actual"
  IFS=. read -r x y z <<< "$required"
  a=${a:-0}; b=${b:-0}; c=${c:-0}; x=${x:-0}; y=${y:-0}; z=${z:-0}
  (( a > x || (a == x && b > y) || (a == x && b == y && c >= z) ))
}

plist_value() { /usr/libexec/PlistBuddy -c "Print :$2" "$1/Contents/Info.plist"; }

verify_app() {
  local app="$1" minimum executable
  [ -d "$app" ] || fail "App not found: $app"
  [ "$(plist_value "$app" CFBundleIdentifier)" = com.anysphere.sand ] || fail 'Unexpected app identifier.'
  executable=$(plist_value "$app" CFBundleExecutable)
  [ "$executable" = 'Grok Bot' ] || fail 'Unexpected app executable.'
  file "$app/Contents/MacOS/$executable" | grep -q x86_64 || fail 'The app does not contain an Intel executable.'
  minimum=$(plist_value "$app" LSMinimumSystemVersion)
  version_at_least "$(sw_vers -productVersion)" "$minimum" || fail "This version requires macOS $minimum or later."
  # Check both the sealed resources and the expected Apple-issued developer identity.
  codesign --verify --deep --strict -R '=identifier "com.anysphere.sand" and anchor apple generic and certificate leaf[subject.OU] = "DCNK4UB866"' "$app" ||
    fail 'App signature or developer identity verification failed. Download a fresh official installer.'
  spctl --assess --type execute --verbose=2 "$app" || fail 'macOS Gatekeeper did not accept this app.'
  printf 'Verified Grok Bot %s (Intel; minimum macOS %s).\n' "$(plist_value "$app" CFBundleShortVersionString)" "$minimum"
}

app_is_running() {
  # Match the application executable, without inspecting arguments or account data.
  local processes
  processes=$(ps -axo comm=) || fail 'Cannot inspect running applications. Try again from Terminal.'
  printf '%s\n' "$processes" | grep -E '/Grok Bot\.app/Contents/MacOS/Grok Bot$' >/dev/null
}
