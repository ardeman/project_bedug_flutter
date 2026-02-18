#!/usr/bin/env sh

set -eu

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

staged_dart_files="$(
  git diff --cached --name-only --diff-filter=ACMR \
    | grep -E '\.dart$' || true
)"

if [ -z "$staged_dart_files" ]; then
  echo "No staged Dart files. Skipping flutter analyze."
  exit 0
fi

echo "Running flutter analyze on staged Dart files:"
printf '%s\n' "$staged_dart_files"

flutter analyze $staged_dart_files

