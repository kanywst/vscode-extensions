#!/usr/bin/env bash
# Install every extension listed in extensions.list.
# Idempotent: already-installed extensions are skipped by the editor.

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

if [ ! -f "${LIST_FILE}" ]; then
  echo "error: ${LIST_FILE} not found." >&2
  exit 1
fi

failed=()
while IFS= read -r ext; do
  [ -z "${ext}" ] && continue
  echo "==> ${ext}"
  if ! "${CODE_BIN}" --install-extension "${ext}" --force; then
    failed+=("${ext}")
  fi
done < <(tracked_extensions)

if [ "${#failed[@]}" -gt 0 ]; then
  echo
  echo "Failed to install ${#failed[@]} extension(s):" >&2
  printf '  %s\n' "${failed[@]}" >&2
  exit 1
fi

echo
echo "All tracked extensions installed."
