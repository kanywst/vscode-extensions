#!/usr/bin/env bash
# Verify extensions.list is in canonical form: lowercased, LC_ALL=C sorted,
# de-duplicated, no comments or blank lines. Catches hand-edits that bypass
# bin/export.sh. Exits non-zero on drift. Needs no editor CLI, so it runs in CI.

# shellcheck source=bin/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

if [ ! -f "${LIST_FILE}" ]; then
  echo "error: ${LIST_FILE} not found." >&2
  exit 1
fi

status=0

# tracked_extensions() applies the exact canonical form. If the file already is
# canonical, it round-trips to itself.
if ! diff -u "${LIST_FILE}" <(tracked_extensions) >/dev/null; then
  echo "extensions.list is not in canonical form (lowercase + LC_ALL=C sort, no comments/blanks)." >&2
  echo "Re-run 'bin/export.sh' to regenerate it. Diff (- file, + canonical):" >&2
  diff -u "${LIST_FILE}" <(tracked_extensions) | tail -n +4 >&2 || true
  status=1
fi

dupes="$(tracked_extensions | LC_ALL=C uniq -d)"
if [ -n "${dupes}" ]; then
  echo "Duplicate extension IDs:" >&2
  echo "${dupes}" | sed 's/^/  /' >&2
  status=1
fi

if [ "${status}" -eq 0 ]; then
  echo "extensions.list is canonical."
fi

exit "${status}"
