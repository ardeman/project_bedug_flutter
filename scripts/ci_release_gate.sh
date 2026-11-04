#!/usr/bin/env bash
set -euo pipefail

run=true

if [[ "${RELEASE_PIPELINE:-false}" != "true" &&
  "${GITHUB_EVENT_NAME:-}" == "push" &&
  "${GITHUB_REF:-}" == "refs/heads/master" ]]; then
  before="${GITHUB_EVENT_BEFORE:-}"
  if [[ -n "$before" && "$before" != "0000000000000000000000000000000000000000" ]]; then
    old_version="$(
      git show "$before:pubspec.yaml" 2>/dev/null |
        sed -n 's/^version: *//p' | cut -d+ -f1 || true
    )"
    new_version="$(sed -n 's/^version: *//p' pubspec.yaml | cut -d+ -f1)"

    if [[ -n "$old_version" && -n "$new_version" &&
      "$old_version" != "$new_version" ]]; then
      if gh release view "v$new_version" \
        --repo "$GITHUB_REPOSITORY" >/dev/null 2>&1; then
        echo "Release v$new_version already exists; running standalone CI."
      else
        run=false
        echo "A release workflow will check and build v$new_version; skipping duplicate CI."
      fi
    fi
  fi
fi

echo "run=$run" >> "$GITHUB_OUTPUT"
