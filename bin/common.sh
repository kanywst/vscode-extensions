#!/usr/bin/env bash
# Shared helpers for the extension-management scripts.
# Sourced by export.sh / install.sh / diff.sh — not run directly.

set -euo pipefail

# Repo root (parent of bin/).
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIST_FILE="${REPO_ROOT}/extensions.list"

# Editor CLI. Override for Cursor / VSCodium / Insiders, e.g. CODE_BIN=cursor.
CODE_BIN="${CODE_BIN:-code}"

if ! command -v "${CODE_BIN}" >/dev/null 2>&1; then
  echo "error: '${CODE_BIN}' CLI not found on PATH." >&2
  echo "  Install it from VS Code: Command Palette -> 'Shell Command: Install code command in PATH'." >&2
  echo "  Or point at another editor: CODE_BIN=cursor $0" >&2
  exit 1
fi

# Installed extension IDs, lowercased + sorted, one per line.
installed_extensions() {
  "${CODE_BIN}" --list-extensions | tr '[:upper:]' '[:lower:]' | LC_ALL=C sort
}

# Tracked extension IDs from the list file: strip comments / blanks, lowercase, sort.
tracked_extensions() {
  [ -f "${LIST_FILE}" ] || return 0
  sed -e 's/#.*//' -e 's/[[:space:]]//g' "${LIST_FILE}" \
    | grep -v '^$' \
    | tr '[:upper:]' '[:lower:]' \
    | LC_ALL=C sort
}
