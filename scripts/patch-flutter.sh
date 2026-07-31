#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is not available on PATH." >&2
  exit 1
fi

FLUTTER_BIN="$(readlink -f "$(command -v flutter)")"
FLUTTER_ROOT="$(cd "$(dirname "${FLUTTER_BIN}")/.." && pwd)"
PATCH_FILE="${PROJECT_ROOT}/patches/flutter_3.24.4_dropdown_menu_enableFilter.diff"
FLUTTER_VERSION="$(flutter --version)"

if [[ "${FLUTTER_VERSION}" != *"Flutter 3.24.4"* && \
      "${FLUTTER_VERSION}" != *"Flutter 3.24.5"* ]]; then
  echo "This patch is only intended for Flutter 3.24.4 or 3.24.5." >&2
  echo "Detected: ${FLUTTER_VERSION}" >&2
  exit 1
fi

if git -C "${FLUTTER_ROOT}" apply --reverse --check "${PATCH_FILE}" \
    >/dev/null 2>&1; then
  echo "Flutter dropdown patch is already applied."
  exit 0
fi

git -C "${FLUTTER_ROOT}" apply --check "${PATCH_FILE}"
git -C "${FLUTTER_ROOT}" apply "${PATCH_FILE}"
echo "Flutter dropdown patch applied to ${FLUTTER_ROOT}."
