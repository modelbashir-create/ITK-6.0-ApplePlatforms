#!/usr/bin/env bash
set -euo pipefail

# Source root for the iOS-specific ITK tree
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${ROOT_DIR}"

# Build + install directories for iOS *device*
BUILD_DIR="${ROOT_DIR}/build-ios-device"
INSTALL_DIR="${ROOT_DIR}/install-ios-device"

echo "Root dir:    ${ROOT_DIR}"
echo "Source dir:  ${SRC_DIR}"
echo "Build dir:   ${BUILD_DIR}"
echo "Install dir: ${INSTALL_DIR}"
echo

# Clean build + install dir so flag/module changes actually apply
rm -rf "${BUILD_DIR}" "${INSTALL_DIR}"
mkdir -p "${BUILD_DIR}" "${INSTALL_DIR}"
cd "${BUILD_DIR}"

echo "Configuring ITK for iOS (device, arm64)..."
cmake "${SRC_DIR}" \
  -G Xcode \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_SYSROOT=iphoneos \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF \
  -DCMAKE_XCODE_ATTRIBUTE_LLVM_LTO=NO \
  -DCMAKE_XCODE_ATTRIBUTE_ENABLE_BITCODE=NO \
  -DCMAKE_C_FLAGS_RELEASE="-fno-lto" \
  -DCMAKE_CXX_FLAGS_RELEASE="-fno-lto" \
  -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" \
  -DITK_BUILD_DEFAULT_MODULES=ON \
  -DITK_WRAP_PYTHON=OFF \
  -DModule_ITKTestKernel=OFF \
  -DBUILD_TESTING=OFF \
  -DITK_USE_BLAS=ON \
  -DVNL_USE_BLAS=ON \
  -DBLAS_LIBRARIES="-framework Accelerate" \
  -DLAPACK_LIBRARIES="-framework Accelerate" \
  -DBUILD_SHARED_LIBS=OFF \
  -DITK_USE_SYSTEM_EIGEN=OFF \
  -DDOUBLE_CONVERSION_CORRECT_DOUBLE_OPERATIONS:BOOL=ON \
  -DDOUBLE_CONVERSION_CORRECT_DOUBLE_OPERATIONS__TRYRUN_OUTPUT:STRING="" \
  -DVCL_HAS_LFS:BOOL=ON \
  -DVCL_HAS_LFS__TRYRUN_OUTPUT:STRING="" \
  -DModule_ITKMINC=ON \
  -DModule_ITKMINC2=ON \
  -DModule_ITKIOGDCM=ON \
  -DModule_ITKDCMTK=ON

echo
echo "Building ITK for iOS (device, Release)..."
cmake --build . --config Release -- -jobs 8

echo
echo "Installing ITK for iOS (device, Release)..."
cmake --install . --config Release

echo
echo "✅ Done."
echo "  Static libs: ${BUILD_DIR}"
echo "  Installed headers + libs for framework: ${INSTALL_DIR}"
