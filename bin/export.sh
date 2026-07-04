#!/usr/bin/env bash
# Write extensions.list from the installed set. No flag mirrors exactly (so it
# prunes too); --merge adds new ones without removing any (used by pre-commit).

# shellcheck source=bin/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

tmp="$(mktemp)"
trap 'rm -f "${tmp}"' EXIT

if [ "${1:-}" = "--merge" ]; then
  installed_extensions > "${tmp}"
  tracked_extensions >> "${tmp}"
  LC_ALL=C sort -u "${tmp}" -o "${tmp}"
else
  installed_extensions > "${tmp}"
fi

# Write through with cat, not mv, to preserve a symlinked list and its mode.
cat "${tmp}" > "${LIST_FILE}"

count="$(grep -c '' "${LIST_FILE}" || true)"
echo "Exported ${count} extensions to ${LIST_FILE#"${REPO_ROOT}"/}"
