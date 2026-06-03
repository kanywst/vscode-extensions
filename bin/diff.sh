#!/usr/bin/env bash
# Show drift between installed extensions and extensions.list.
# Exit 0 when in sync, 1 when there is drift (handy for CI / pre-commit).

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

installed="$(installed_extensions)"
tracked="$(tracked_extensions)"

to_add="$(LC_ALL=C comm -23 <(echo "${installed}") <(echo "${tracked}"))"
to_remove="$(LC_ALL=C comm -13 <(echo "${installed}") <(echo "${tracked}"))"

drift=0

if [ -n "${to_add}" ]; then
  drift=1
  echo "Installed but NOT in extensions.list (run bin/export.sh to record):"
  echo "${to_add}" | sed 's/^/  + /'
fi

if [ -n "${to_remove}" ]; then
  drift=1
  echo "In extensions.list but NOT installed (run bin/install.sh to add):"
  echo "${to_remove}" | sed 's/^/  - /'
fi

if [ "${drift}" -eq 0 ]; then
  echo "In sync: installed extensions match extensions.list."
fi

exit "${drift}"
