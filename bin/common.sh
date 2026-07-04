#!/usr/bin/env bash
# Shared helpers for the extension-management scripts.
# Sourced by export.sh / install.sh / diff.sh — not run directly.

set -euo pipefail

# Repo root (parent of bin/).
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIST_FILE="${REPO_ROOT}/extensions.list"

# Editor CLI. Override for Cursor / VSCodium / Insiders, e.g. CODE_BIN=cursor.
CODE_BIN="${CODE_BIN:-code}"

# Fail if the editor CLI is missing. Called lazily so list-only tools (lint, CI)
# can source this file without the editor installed.
require_code_bin() {
  command -v "${CODE_BIN}" >/dev/null 2>&1 && return 0
  echo "error: '${CODE_BIN}' CLI not found on PATH." >&2
  echo "  Install it from VS Code: Command Palette -> 'Shell Command: Install code command in PATH'." >&2
  echo "  Or point at another editor: CODE_BIN=cursor $0" >&2
  exit 1
}

# Echo a value only when non-empty. A bare echo of an empty var prints a blank
# line, which comm would treat as an extension ID (phantom drift).
emit() {
  [ -n "${1}" ] && printf '%s\n' "${1}"
  return 0
}

# Installed extension IDs, lowercased + sorted, one per line.
installed_extensions() {
  require_code_bin
  # tr -d '\r': the CLI emits CRLF on Windows/WSL/Git Bash; tracked_extensions
  # already strips it, so drop it here too or every ID looks like drift.
  "${CODE_BIN}" --list-extensions | tr -d '\r' | tr '[:upper:]' '[:lower:]' | LC_ALL=C sort
}

# Tracked extension IDs from the list file: strip comments / blanks, lowercase, sort.
tracked_extensions() {
  [ -f "${LIST_FILE}" ] || return 0
  # Delete blank lines with sed, not grep -v: grep exits 1 on an all-blank list,
  # which would trip pipefail/set -e in every caller.
  sed -e 's/#.*//' -e 's/[[:space:]]//g' -e '/^$/d' "${LIST_FILE}" \
    | tr '[:upper:]' '[:lower:]' \
    | LC_ALL=C sort
}
