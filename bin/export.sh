#!/usr/bin/env bash
# Dump the currently installed extensions into extensions.list.
# Run this after installing/removing extensions, then commit the diff.

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

installed_extensions > "${LIST_FILE}"

count="$(grep -c '' "${LIST_FILE}" || true)"
echo "Exported ${count} extensions to ${LIST_FILE#"${REPO_ROOT}"/}"
