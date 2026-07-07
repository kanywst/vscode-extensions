#!/usr/bin/env bash
# Write extensions.list from the installed set. No flag mirrors exactly (so it
# prunes too); --merge adds new ones without removing any (used by pre-commit).

# shellcheck source=bin/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

tmp="$(mktemp)"
trap 'rm -f "${tmp}"' EXIT

case "${1:-}" in
  --merge)
    installed_extensions > "${tmp}"
    tracked_extensions >> "${tmp}"
    LC_ALL=C sort -u "${tmp}" -o "${tmp}"
    ;;
  "")
    installed_extensions > "${tmp}"
    ;;
  *)
    echo "error: unknown option '${1}' (expected --merge)" >&2
    exit 1
    ;;
esac

# Write through with cat, not mv, to preserve a symlinked list and its mode.
cat "${tmp}" > "${LIST_FILE}"

count="$(grep -c '' "${LIST_FILE}" || true)"
echo "Exported ${count} extensions to ${LIST_FILE#"${REPO_ROOT}"/}"

# Snapshot the rest of the setup (settings / keybindings / snippets) alongside it.
export_config
echo "Synced VS Code config to ${CONFIG_DIR#"${REPO_ROOT}"/}/"
