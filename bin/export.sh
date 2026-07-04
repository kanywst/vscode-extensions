#!/usr/bin/env bash
# Dump the currently installed extensions into extensions.list.
# Run this after installing/removing extensions, then commit the diff.
#
#   bin/export.sh            mirror: overwrite the list with exactly what is
#                            installed now (this is how you PRUNE an extension).
#   bin/export.sh --merge    union: add newly installed extensions to the list
#                            but never remove any. Safe to run on a machine that
#                            only has a subset of the tracked set installed --
#                            it can't wipe the baseline. Used by bin/pre-commit.

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

mv "${tmp}" "${LIST_FILE}"

count="$(grep -c '' "${LIST_FILE}" || true)"
echo "Exported ${count} extensions to ${LIST_FILE#"${REPO_ROOT}"/}"
