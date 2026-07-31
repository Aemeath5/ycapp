#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_command flutter
require_command cargo
require_command flutter_rust_bridge_codegen

if ! cargo expand --version >/dev/null 2>&1; then
  echo "Missing cargo-expand. Install version 1.0.95 first." >&2
  exit 1
fi

cd "${PROJECT_ROOT}"

BRIDGE_FLUTTER_VERSION="$(flutter --version)"
PUBSPEC_BACKUP_DIR=""

restore_pubspec() {
  if [[ -n "${PUBSPEC_BACKUP_DIR}" && -d "${PUBSPEC_BACKUP_DIR}" ]]; then
    cp "${PUBSPEC_BACKUP_DIR}/pubspec.yaml" flutter/pubspec.yaml
    cp "${PUBSPEC_BACKUP_DIR}/pubspec.lock" flutter/pubspec.lock
    rm "${PUBSPEC_BACKUP_DIR}/pubspec.yaml" \
      "${PUBSPEC_BACKUP_DIR}/pubspec.lock"
    rmdir "${PUBSPEC_BACKUP_DIR}"
  fi
}

if [[ "${BRIDGE_FLUTTER_VERSION}" == *"Flutter 3.22.3"* ]]; then
  PUBSPEC_BACKUP_DIR="$(mktemp -d)"
  cp flutter/pubspec.yaml "${PUBSPEC_BACKUP_DIR}/pubspec.yaml"
  cp flutter/pubspec.lock "${PUBSPEC_BACKUP_DIR}/pubspec.lock"
  trap restore_pubspec EXIT
  sed -i \
    's/extended_text: 14.0.0/extended_text: 13.0.0/' \
    flutter/pubspec.yaml
fi

(
  cd flutter
  flutter pub get
)

mkdir -p flutter/android/app/src/main/cpp

flutter_rust_bridge_codegen \
  --rust-input ./src/flutter_ffi.rs \
  --dart-output ./flutter/lib/generated_bridge.dart \
  --c-output ./flutter/android/app/src/main/cpp/bridge_generated.h

for generated_file in \
  src/bridge_generated.rs \
  src/bridge_generated.io.rs \
  flutter/lib/generated_bridge.dart \
  flutter/lib/generated_bridge.freezed.dart; do
  if [[ ! -s "${generated_file}" ]]; then
    echo "Bridge generation did not create ${generated_file}" >&2
    exit 1
  fi
done

echo "Flutter-Rust bridge generated successfully."
