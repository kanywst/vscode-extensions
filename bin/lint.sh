#!/usr/bin/env bash
# Check extensions.list is canonical (lowercased, sorted, deduped, no stray
# lines) so hand-edits that bypass export.sh don't slip in. Needs no editor CLI.

# shellcheck source=bin/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

if [ ! -f "${LIST_FILE}" ]; then
  echo "error: ${LIST_FILE} not found." >&2
  exit 1
fi

status=0
tracked="$(tracked_extensions)"

# A canonical file round-trips through tracked_extensions() unchanged.
if ! diff -u "${LIST_FILE}" <(emit "${tracked}") >/dev/null; then
  echo "extensions.list is not in canonical form (lowercase + LC_ALL=C sort, no comments/blanks)." >&2
  echo "Re-run 'bin/export.sh' to regenerate it. Diff (- file, + canonical):" >&2
  diff -u "${LIST_FILE}" <(emit "${tracked}") | tail -n +4 >&2 || true
  status=1
fi

dupes="$(emit "${tracked}" | LC_ALL=C uniq -d)"
if [ -n "${dupes}" ]; then
  echo "Duplicate extension IDs:" >&2
  emit "${dupes}" | sed 's/^/  /' >&2
  status=1
fi

if [ "${status}" -eq 0 ]; then
  echo "extensions.list is canonical."
fi

exit "${status}"
