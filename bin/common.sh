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

# --- User config (settings / keybindings / snippets) ------------------------
# The list only captures extension IDs; these three carry the rest of a VS Code
# setup. mcp.json is deliberately NOT tracked here — MCP config lives in
# ~/dotclaude, so copying it in would fight that source of truth.

# VS Code stable's User dir, defaulted per-OS (macOS vs Linux/WSL). Override for
# a non-standard install or another editor, mirroring how CODE_BIN swaps the CLI.
if [ -z "${CODE_USER_DIR:-}" ]; then
  case "$(uname -s)" in
    Darwin) CODE_USER_DIR="${HOME}/Library/Application Support/Code/User" ;;
    *)      CODE_USER_DIR="${HOME}/.config/Code/User" ;;
  esac
fi
# Repo-tracked copy of that config.
CONFIG_DIR="${REPO_ROOT}/config"
# Flat files mirrored verbatim between the two dirs.
CONFIG_FILES=(settings.json keybindings.json)

# Copy a file only when the source exists; make the parent dir first. Always
# returns 0 so a missing optional file (e.g. no keybindings yet) can't trip set -e.
copy_if_present() {
  local src="${1}" dst="${2}"
  [ -f "${src}" ] || return 0
  mkdir -p "$(dirname "${dst}")"
  cp "${src}" "${dst}"
}

# Mirror snippet files from src/ into dst/ (files only). Keeps .gitkeep only in
# the tracked repo copy (so the empty frame survives in git) and never leaves it
# in the live dir, where VS Code would try to parse it as a snippet.
mirror_snippets() {
  local src="${1}" dst="${2}"
  # Replace dst wholesale instead of pruning files in place: rm -rf drops a
  # symlinked dir to just its link (not the target's neighbours) and sidesteps
  # BSD find's refusal to traverse a symlinked path without a trailing slash,
  # keeping this consistent with how the flat files replace a symlink.
  rm -rf "${dst}"
  mkdir -p "${dst}"
  # Don't hide cp errors: under set -e a silent failure here would abort the
  # whole restore with no clue why. Let stderr through.
  [ -d "${src}" ] && cp -R "${src}/." "${dst}/"
  if [ "${dst}" = "${CONFIG_DIR}/snippets" ]; then
    touch "${dst}/.gitkeep"
  else
    rm -f "${dst}/.gitkeep"
  fi
  return 0
}

# Export the live VS Code config into the repo's config/ dir.
export_config() {
  local f
  for f in "${CONFIG_FILES[@]}"; do
    copy_if_present "${CODE_USER_DIR}/${f}" "${CONFIG_DIR}/${f}"
  done
  mirror_snippets "${CODE_USER_DIR}/snippets" "${CONFIG_DIR}/snippets"
}

# Restore the repo's config/ into the live VS Code User dir. Any existing file
# that differs is backed up to <file>.bak first, so a re-run on a used machine
# stays recoverable instead of silently clobbering local tweaks.
install_config() {
  local f src dst
  mkdir -p "${CODE_USER_DIR}"
  for f in "${CONFIG_FILES[@]}"; do
    src="${CONFIG_DIR}/${f}"
    dst="${CODE_USER_DIR}/${f}"
    [ -f "${src}" ] || continue
    # dst may be a symlink into a dotfiles repo. Skip when content already
    # matches; otherwise back up the current target and replace the link/file
    # itself (rm then cp) instead of writing through the symlink.
    if [ -L "${dst}" ] || [ -f "${dst}" ]; then
      diff -q "${src}" "${dst}" >/dev/null 2>&1 && continue
      [ -e "${dst}" ] && cp "${dst}" "${dst}.bak"
      rm -f "${dst}"
    fi
    cp "${src}" "${dst}"
  done
  # Only restore snippets when the repo tracks them, so an absent config/snippets
  # can't silently wipe the live set. Back up differing live snippets to
  # snippets.bak first, same recoverability as the flat files above.
  if [ -d "${CONFIG_DIR}/snippets" ]; then
    if [ -d "${CODE_USER_DIR}/snippets" ] \
      && ! diff -rq -x .gitkeep \
        "${CONFIG_DIR}/snippets/" "${CODE_USER_DIR}/snippets/" >/dev/null 2>&1; then
      rm -rf "${CODE_USER_DIR}/snippets.bak"
      cp -R "${CODE_USER_DIR}/snippets" "${CODE_USER_DIR}/snippets.bak"
    fi
    mirror_snippets "${CONFIG_DIR}/snippets" "${CODE_USER_DIR}/snippets"
  fi
}

# Print one drift line per config difference between repo and live dir; prints
# nothing when they match. Callers fold non-empty output into their exit code.
diff_config() {
  local f src dst repo_has live_has
  for f in "${CONFIG_FILES[@]}"; do
    src="${CONFIG_DIR}/${f}"
    dst="${CODE_USER_DIR}/${f}"
    if [ -f "${src}" ] && [ ! -f "${dst}" ]; then
      printf '  live-missing %s\n' "${f}"
    elif [ ! -f "${src}" ] && [ -f "${dst}" ]; then
      printf '  untracked    %s\n' "${f}"
    elif [ -f "${src}" ] && ! diff -q "${src}" "${dst}" >/dev/null; then
      printf '  differs      %s\n' "${f}"
    fi
  done
  # Compare real snippet files only (ignore .gitkeep). Flag drift when one side
  # has snippets and the other doesn't, as well as when both differ in content.
  repo_has=0
  live_has=0
  # Trailing slash forces BSD find/diff to traverse a symlinked snippets dir;
  # -x is the portable spelling of diff's exclude (GNU + BSD), unlike --exclude.
  [ -n "$(find "${CONFIG_DIR}/snippets/" -type f ! -name '.gitkeep' 2>/dev/null)" ] && repo_has=1
  [ -n "$(find "${CODE_USER_DIR}/snippets/" -type f 2>/dev/null)" ] && live_has=1
  if [ "${repo_has}" -ne "${live_has}" ]; then
    printf '  differs      snippets/\n'
  elif [ "${repo_has}" -eq 1 ]; then
    [ -n "$(diff -rq -x .gitkeep \
        "${CONFIG_DIR}/snippets/" "${CODE_USER_DIR}/snippets/" 2>/dev/null)" ] \
      && printf '  differs      snippets/\n'
  fi
  return 0
}
