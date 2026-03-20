#!/usr/bin/env bash
set -euo pipefail

# Source root for the iOS-specific ITK tree
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${ROOT_DIR}"

# Build + install directories for iOS *simulator*
BUILD_DIR="${ROOT_DIR}/build-ios-sim"
INSTALL_DIR="${ROOT_DIR}/install-ios-sim"

echo "Root dir:    ${ROOT_DIR}"
echo "Source dir:  ${SRC_DIR}"
echo "Build dir:   ${BUILD_DIR}"
echo "Install dir: ${INSTALL_DIR}"
echo

# Clean build + install dir so flag/module changes actually apply
rm -rf "${BUILD_DIR}" "${INSTALL_DIR}"
mkdir -p "${BUILD_DIR}" "${INSTALL_DIR}"
cd "${BUILD_DIR}"

# Cache file to satisfy CMake try_run() in cross-compile mode (iOS simulator)
CACHE_FILE="${BUILD_DIR}/InitialCache_ios_sim.cmake"

cat > "${CACHE_FILE}" << 'CACHE_EOF'
# Pre-fill results for cross-compilation so try_run() doesn't fail.

# double-conversion: assume operations are correct
set(DOUBLE_CONVERSION_CORRECT_DOUBLE_OPERATIONS 1 CACHE STRING "double-conversion behaves correctly" FORCE)

# VNL large file support: treat as disabled on iOS
set(VCL_HAS_LFS 0 CACHE STRING "no large file support needed on iOS" FORCE)

# libc++ detection: pretend try_run succeeded and libc++ is recent
set(_libcxx_run_result 0 CACHE STRING "pretend try_run succeeded" FORCE)
set(_using_libcxx 1 CACHE STRING "use libc++" FORCE)
set(_libcxx_version 1102 CACHE STRING "libc++ version (>= 1102)" FORCE)

# Quiet-NaN 22nd bit (NrrdIO / Teem)
set(QNANHIBIT_VALUE "1" CACHE STRING "Result of try_run for 22nd bit of 32-bit quiet-NaN" FORCE)
set(QNANHIBIT_VALUE__TRYRUN_OUTPUT "" CACHE STRING "Output of try_run for 22nd bit of 32-bit quiet-NaN" FORCE)
CACHE_EOF

echo "Configuring ITK for iOS Simulator (arm64)..."
cmake "${SRC_DIR}" \
  -C "${CACHE_FILE}" \
  -G Xcode \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_SYSROOT=iphonesimulator \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF \
  -DCMAKE_XCODE_ATTRIBUTE_LLVM_LTO=NO \
  -DCMAKE_XCODE_ATTRIBUTE_ENABLE_BITCODE=NO \
  -DCMAKE_C_FLAGS_RELEASE="-O3 -fno-lto" \
  -DCMAKE_CXX_FLAGS_RELEASE="-O3 -fno-lto" \
  -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" \
  -DITK_USE_BLAS=ON \
  -DVNL_USE_BLAS=ON \
  -DBLAS_LIBRARIES="-framework Accelerate" \
  -DLAPACK_LIBRARIES="-framework Accelerate" \
  -DBUILD_SHARED_LIBS=OFF \
  -DITK_BUILD_DEFAULT_MODULES=ON \
  -DITK_WRAP_PYTHON=OFF \
  -DModule_ITKTestKernel=OFF \
  -DBUILD_TESTING=OFF \
  -DModule_ITKMINC=ON \
  -DModule_ITKMINC2=ON \
  -DModule_ITKIOGDCM=ON \
  -DModule_ITKDCMTK=ON

echo
echo "Building ITK for iOS Simulator (Release)..."
cmake --build . --config Release -- -jobs 8

echo
echo "Installing ITK for iOS Simulator (Release)..."
cmake --install . --config Release

echo
echo "✅ Done."
echo "  Static libs: ${BUILD_DIR}"
echo "  Installed headers + libs for framework: ${INSTALL_DIR}"
