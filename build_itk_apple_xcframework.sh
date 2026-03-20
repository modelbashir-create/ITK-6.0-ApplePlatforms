#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_ROOT="${ROOT_DIR}/itk-ios"
MAC_ROOT="${ROOT_DIR}/itk-macos"
VISION_ROOT="${ROOT_DIR}/itk-visionos"

DEFAULT_OUTPUT="${ROOT_DIR}/out/ITK.xcframework"
RAW_OUTPUT_XCFRAMEWORK="${1:-${DEFAULT_OUTPUT}}"
RAW_OUTPUT_DIR="$(dirname "${RAW_OUTPUT_XCFRAMEWORK}")"
mkdir -p "${RAW_OUTPUT_DIR}"
OUTPUT_XCFRAMEWORK="$(cd "${RAW_OUTPUT_DIR}" && pwd)/$(basename "${RAW_OUTPUT_XCFRAMEWORK}")"

STAGING_DIR="${ROOT_DIR}/out/rebuild-staging"

require_file() {
  local path="$1"
  if [[ ! -f "${path}" ]]; then
    echo "Missing required file: ${path}" >&2
    exit 1
  fi
}

require_dir() {
  local path="$1"
  if [[ ! -d "${path}" ]]; then
    echo "Missing required directory: ${path}" >&2
    exit 1
  fi
}

run_platform_builds() {
  echo "Running iOS device build..."
  "${IOS_ROOT}/build_ios_device.sh"

  echo
  echo "Running iOS simulator build..."
  "${IOS_ROOT}/build_ios_sim.sh"

  echo
  echo "Running macOS build..."
  "${MAC_ROOT}/build_macos.sh"

  echo
  echo "Running visionOS device build..."
  "${VISION_ROOT}/build_visionos_device.sh"

  echo
  echo "Running visionOS simulator build..."
  "${VISION_ROOT}/build_visionos_sim.sh"
}

combine_archives() {
  local slice_name="$1"
  local lib_dir="$2"
  local out_name="$3"

  require_dir "${lib_dir}"
  mkdir -p "${STAGING_DIR}/${slice_name}"
  libtool -static -o "${STAGING_DIR}/${slice_name}/${out_name}" "${lib_dir}"/*.a
}

copy_missing_eigen_if_needed() {
  local sim_headers="${OUTPUT_XCFRAMEWORK}/xros-arm64-simulator/Headers"
  local device_eigen="${VISION_ROOT}/install-visionos-device/include/ITK-6.0/itkeigen"

  if [[ ! -d "${sim_headers}/itkeigen" && -d "${device_eigen}" ]]; then
    cp -R "${device_eigen}" "${sim_headers}/itkeigen"
  fi
}

package_xcframework() {
  rm -rf "${STAGING_DIR}" "${OUTPUT_XCFRAMEWORK}"
  mkdir -p "${STAGING_DIR}" "$(dirname "${OUTPUT_XCFRAMEWORK}")"

  combine_archives "ios-arm64" "${IOS_ROOT}/install-ios-device/lib" "libITK_ios_device.a"
  combine_archives "ios-arm64-simulator" "${IOS_ROOT}/install-ios-sim/lib" "libITK_ios_simulator.a"
  combine_archives "macos-arm64" "${MAC_ROOT}/install-macos/lib" "libITK_macos.a"
  combine_archives "xros-arm64" "${VISION_ROOT}/install-visionos-device/lib" "libITK_visionos_device.a"
  combine_archives "xros-arm64-simulator" "${VISION_ROOT}/install-visionos-sim/lib" "libITK_visionos_simulator.a"

  require_dir "${IOS_ROOT}/install-ios-device/include/ITK-6.0"
  require_dir "${IOS_ROOT}/install-ios-sim/include/ITK-6.0"
  require_dir "${MAC_ROOT}/install-macos/include/ITK-6.0"
  require_dir "${VISION_ROOT}/install-visionos-device/include/ITK-6.0"
  require_dir "${VISION_ROOT}/install-visionos-sim/include/ITK-6.0"

  xcodebuild -create-xcframework \
    -library "${STAGING_DIR}/ios-arm64/libITK_ios_device.a" -headers "${IOS_ROOT}/install-ios-device/include/ITK-6.0" \
    -library "${STAGING_DIR}/ios-arm64-simulator/libITK_ios_simulator.a" -headers "${IOS_ROOT}/install-ios-sim/include/ITK-6.0" \
    -library "${STAGING_DIR}/macos-arm64/libITK_macos.a" -headers "${MAC_ROOT}/install-macos/include/ITK-6.0" \
    -library "${STAGING_DIR}/xros-arm64/libITK_visionos_device.a" -headers "${VISION_ROOT}/install-visionos-device/include/ITK-6.0" \
    -library "${STAGING_DIR}/xros-arm64-simulator/libITK_visionos_simulator.a" -headers "${VISION_ROOT}/install-visionos-sim/include/ITK-6.0" \
    -output "${OUTPUT_XCFRAMEWORK}"

  copy_missing_eigen_if_needed
}

verify_output() {
  local required=(
    "${OUTPUT_XCFRAMEWORK}/ios-arm64/libITK_ios_device.a"
    "${OUTPUT_XCFRAMEWORK}/ios-arm64-simulator/libITK_ios_simulator.a"
    "${OUTPUT_XCFRAMEWORK}/macos-arm64/libITK_macos.a"
    "${OUTPUT_XCFRAMEWORK}/xros-arm64/libITK_visionos_device.a"
    "${OUTPUT_XCFRAMEWORK}/xros-arm64-simulator/libITK_visionos_simulator.a"
  )

  for file in "${required[@]}"; do
    require_file "${file}"
  done

  echo
  echo "Created xcframework:"
  echo "  ${OUTPUT_XCFRAMEWORK}"
  find "${OUTPUT_XCFRAMEWORK}" -maxdepth 2 \( -name '*.a' -o -name Headers \) | sort
}

main() {
  echo "Project root:    ${ROOT_DIR}"
  echo "Output path:     ${OUTPUT_XCFRAMEWORK}"
  echo

  run_platform_builds
  echo
  echo "Packaging ITK.xcframework..."
  package_xcframework
  verify_output
}

main "$@"
