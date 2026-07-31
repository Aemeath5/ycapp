#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ANDROID_ABI="${1:-arm64-v8a}"

case "${ANDROID_ABI}" in
  arm64-v8a)
    RUST_TARGET="aarch64-linux-android"
    FLUTTER_TARGET="android-arm64"
    VCPKG_TARGET="arm64-android"
    NDK_LIB_TARGET="aarch64-linux-android"
    RUST_FEATURES="flutter,hwcodec"
    ;;
  armeabi-v7a)
    RUST_TARGET="armv7-linux-androideabi"
    FLUTTER_TARGET="android-arm"
    VCPKG_TARGET="arm-neon-android"
    NDK_LIB_TARGET="arm-linux-androideabi"
    RUST_FEATURES="flutter,hwcodec"
    ;;
  x86_64)
    RUST_TARGET="x86_64-linux-android"
    FLUTTER_TARGET="android-x64"
    VCPKG_TARGET="x64-android"
    NDK_LIB_TARGET="x86_64-linux-android"
    RUST_FEATURES="flutter"
    ;;
  x86)
    RUST_TARGET="i686-linux-android"
    FLUTTER_TARGET="android-x86"
    VCPKG_TARGET="x86-android"
    NDK_LIB_TARGET="i686-linux-android"
    RUST_FEATURES="flutter"
    ;;
  *)
    echo "Unsupported ABI: ${ANDROID_ABI}" >&2
    echo "Use arm64-v8a, armeabi-v7a, x86_64, or x86." >&2
    exit 1
    ;;
esac

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_command cargo
require_command flutter
require_command rustup

if ! cargo ndk --version >/dev/null 2>&1; then
  echo "Missing cargo-ndk. Install version 3.1.2 first." >&2
  exit 1
fi

if [[ -z "${ANDROID_NDK_HOME:-}" && -n "${ANDROID_NDK_ROOT:-}" ]]; then
  export ANDROID_NDK_HOME="${ANDROID_NDK_ROOT}"
fi

if [[ -z "${ANDROID_NDK_HOME:-}" || ! -d "${ANDROID_NDK_HOME}" ]]; then
  echo "ANDROID_NDK_HOME must point to Android NDK r28c." >&2
  exit 1
fi

if [[ -z "${VCPKG_ROOT:-}" || ! -x "${VCPKG_ROOT}/vcpkg" ]]; then
  echo "VCPKG_ROOT must point to a bootstrapped vcpkg checkout." >&2
  exit 1
fi

cd "${PROJECT_ROOT}"

if [[ ! -s src/bridge_generated.rs || \
      ! -s flutter/lib/generated_bridge.dart ]]; then
  "${SCRIPT_DIR}/generate-bridge.sh"
else
  (
    cd flutter
    flutter pub get
  )
fi

"${VCPKG_ROOT}/vcpkg" install \
  --triplet "${VCPKG_TARGET}" \
  --x-install-root="${VCPKG_ROOT}/installed"

if [[ "${ANDROID_ABI}" == "armeabi-v7a" && \
      -d "${VCPKG_ROOT}/installed/arm-neon-android" && \
      ! -e "${VCPKG_ROOT}/installed/arm-android" ]]; then
  mv "${VCPKG_ROOT}/installed/arm-neon-android" \
    "${VCPKG_ROOT}/installed/arm-android"
fi

rustup target add "${RUST_TARGET}"
cargo ndk \
  --platform 21 \
  --target "${RUST_TARGET}" \
  build \
  --release \
  --lib \
  --features "${RUST_FEATURES}"

JNI_DIR="${PROJECT_ROOT}/flutter/android/app/src/main/jniLibs/${ANDROID_ABI}"
mkdir -p "${JNI_DIR}"
cp "${PROJECT_ROOT}/target/${RUST_TARGET}/release/liblibrustdesk.so" \
  "${JNI_DIR}/librustdesk.so"

NDK_PREBUILT_ROOT="${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt"
NDK_HOST_TOOLCHAIN=""
for candidate in "${NDK_PREBUILT_ROOT}"/*; do
  if [[ -d "${candidate}" ]]; then
    NDK_HOST_TOOLCHAIN="${candidate}"
    break
  fi
done

if [[ -z "${NDK_HOST_TOOLCHAIN}" ]]; then
  echo "Unable to locate the NDK LLVM host toolchain." >&2
  exit 1
fi

LIBCXX_SHARED="${NDK_HOST_TOOLCHAIN}/sysroot/usr/lib/${NDK_LIB_TARGET}/libc++_shared.so"
if [[ ! -f "${LIBCXX_SHARED}" ]]; then
  echo "Unable to locate ${LIBCXX_SHARED}" >&2
  exit 1
fi
cp "${LIBCXX_SHARED}" "${JNI_DIR}/"

(
  cd flutter
  flutter build apk \
    --release \
    --target-platform "${FLUTTER_TARGET}" \
    --split-per-abi
)

APK_SOURCE="${PROJECT_ROOT}/flutter/build/app/outputs/flutter-apk/app-${ANDROID_ABI}-release.apk"
APK_DESTINATION="${PROJECT_ROOT}/dist/rustdesk-hyperos-${ANDROID_ABI}.apk"
if [[ ! -f "${APK_SOURCE}" ]]; then
  echo "Flutter completed without creating ${APK_SOURCE}" >&2
  exit 1
fi

mkdir -p "${PROJECT_ROOT}/dist"
cp "${APK_SOURCE}" "${APK_DESTINATION}"
echo "APK created: ${APK_DESTINATION}"
