#!/usr/bin/env bash
# Shared helpers for the extension-management scripts.
# Sourced by export.sh / install.sh / diff.sh — not run directly.

set -euo pipefail

# Repo root (parent of bin/).
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIST_FILE="${REPO_ROOT}/extensions.list"

# Editor CLI. Override for Cursor / VSCodium / Insiders, e.g. CODE_BIN=cursor.
CODE_BIN="${CODE_BIN:-code}"

# Hard-fail if the editor CLI is missing. Called lazily by the functions that
# actually need it, so list-only tooling (bin/lint.sh, CI) can source this file
# and read extensions.list on a machine without the editor installed.
require_code_bin() {
  command -v "${CODE_BIN}" >/dev/null 2>&1 && return 0
  echo "error: '${CODE_BIN}' CLI not found on PATH." >&2
  echo "  Install it from VS Code: Command Palette -> 'Shell Command: Install code command in PATH'." >&2
  echo "  Or point at another editor: CODE_BIN=cursor $0" >&2
  exit 1
}

# Installed extension IDs, lowercased + sorted, one per line.
installed_extensions() {
  require_code_bin
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
