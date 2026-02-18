#!/usr/bin/env sh

set -eu

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <commit-msg-file>"
  exit 1
fi

msg_file="$1"
subject="$(head -n1 "$msg_file" | tr -d '\r')"

pattern='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-z0-9._/-]+\))?!?: .+'

if printf '%s\n' "$subject" | grep -Eq "$pattern"; then
  exit 0
fi

cat <<'EOF'
Invalid commit message format.

Expected:
  <type>(<scope>): <description>

Examples:
  fix(theme): apply app-theme brightness immediately
  docs(readme): add commit message validation guide
EOF

exit 1
