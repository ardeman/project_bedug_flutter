#!/usr/bin/env sh

set -eu

repo_root="$(git rev-parse --show-toplevel)"
hooks_path="$repo_root/.githooks"

chmod +x "$repo_root/scripts/validate_commit_msg.sh"
chmod +x "$repo_root/scripts/analyze_staged_dart.sh"
chmod +x "$hooks_path/commit-msg"
chmod +x "$hooks_path/pre-commit"
git config core.hooksPath .githooks

echo "Git hooks installed."
echo "core.hooksPath=$(git config --get core.hooksPath)"
