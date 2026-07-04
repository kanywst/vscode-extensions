#!/usr/bin/env bash
# Install every extension listed in extensions.list.
# Idempotent: already-installed extensions are updated/skipped by the editor.

# shellcheck source=bin/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

if [ ! -f "${LIST_FILE}" ]; then
  echo "error: ${LIST_FILE} not found." >&2
  exit 1
fi

require_code_bin

# One editor launch for the whole list: a single argv of repeated flags.
args=()
count=0
while IFS= read -r ext; do
  [ -z "${ext}" ] && continue
  args+=(--install-extension "${ext}")
  count=$((count + 1))
done < <(tracked_extensions)

if [ "${count}" -eq 0 ]; then
  echo "extensions.list is empty; nothing to install."
  exit 0
fi

echo "Installing ${count} extensions..."
# --force also updates to latest; don't abort if one ID is missing, report below.
"${CODE_BIN}" "${args[@]}" --force || true

# Assign first so a failed listing trips set -e instead of comm seeing empty input.
installed="$(installed_extensions)"
tracked="$(tracked_extensions)"
missing="$(LC_ALL=C comm -13 <(emit "${installed}") <(emit "${tracked}"))"

if [ -n "${missing}" ]; then
  echo
  echo "Failed to install (not found for '${CODE_BIN}'):" >&2
  echo "${missing}" | sed 's/^/  - /' >&2
  exit 1
fi

echo
echo "All tracked extensions installed."
