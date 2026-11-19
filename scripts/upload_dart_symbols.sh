#!/bin/sh
# Uploads the Dart debug symbols of an iOS release build to Crashlytics, so
# Dart frames in crash reports are readable.
#
# Release builds keep Dart symbols out of the app with
#   flutter build ipa --release --split-debug-info=build/debug-info ...
# (see CLAUDE.md, "Run"). Native code is covered by the "Upload Crashlytics
# dSYMs" build phase; this script adds the Dart side. No --obfuscate: crash
# reports send the exception's type name (lib/shared/services/crash/), which
# obfuscation would turn into a meaningless one.
#
# Usage: scripts/upload_dart_symbols.sh [symbols-dir]   (default build/debug-info)
# Needs the Firebase CLI, signed in once with `firebase login`. Run it after
# every release build, from the project root.

set -eu

dir="${1:-build/debug-info}"
plist="ios/Runner/GoogleService-Info.plist"

if ! ls "$dir"/*.symbols >/dev/null 2>&1; then
  echo "No Dart symbols in $dir: build with --split-debug-info=$dir first." >&2
  exit 1
fi
if ! command -v firebase >/dev/null 2>&1; then
  echo "Firebase CLI not found: npm install -g firebase-tools, then firebase login." >&2
  exit 1
fi

# The Firebase iOS app id (not a secret) from the app's own config.
app_id=$(/usr/libexec/PlistBuddy -c 'Print :GOOGLE_APP_ID' "$plist")

firebase crashlytics:symbols:upload --app="$app_id" "$dir"
