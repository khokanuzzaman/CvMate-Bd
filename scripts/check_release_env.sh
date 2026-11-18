#!/bin/sh
# Refuses a Release build whose .env turns on the mock AI (USE_MOCK_AI=true).
#
# Used by the "Check Release .env" build phase of ios/Runner.xcodeproj; the
# Android check lives in android/app/build.gradle.kts.
#
# Usage: CONFIGURATION=Release scripts/check_release_env.sh [path/to/.env]
# The .env defaults to "$SRCROOT/../.env" (the project root seen from ios/).
# Exits 1 for a Release build with the mock on; 0 otherwise, including when
# the .env or the key is missing. Only the USE_MOCK_AI line is read.

set -eu

case "${CONFIGURATION:-}" in
  Release) ;;
  *) exit 0 ;;
esac

env_file="${1:-${SRCROOT:-.}/../.env}"
[ -f "$env_file" ] || exit 0

# The last uncommented USE_MOCK_AI line wins; drop a trailing " # comment",
# spaces, quotes and CR, then compare case-insensitively.
value=$(grep -E '^[[:space:]]*(export[[:space:]]+)?USE_MOCK_AI[[:space:]]*=' "$env_file" |
  tail -n 1 |
  sed -e 's/^[^=]*=//' -e 's/[[:space:]]#.*$//' |
  tr -d ' \t\r"'"'" |
  tr '[:upper:]' '[:lower:]')

case "$value" in
  true | 1 | yes)
    echo "error: Release build refused: .env has USE_MOCK_AI=true. Set it to false or remove it." >&2
    exit 1
    ;;
esac
exit 0
