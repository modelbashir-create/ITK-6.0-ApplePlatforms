#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${ROOT_DIR}"

# Build + install directories
BUILD_DIR="${ROOT_DIR}/build-macos"
INSTALL_DIR="${ROOT_DIR}/install-macos"

echo "Root dir:    ${ROOT_DIR}"
echo "Source dir:  ${SRC_DIR}"
echo "Build dir:   ${BUILD_DIR}"
echo "Install dir: ${INSTALL_DIR}"
echo

# Start from a clean build/install directory so options take effect
rm -rf "${BUILD_DIR}" "${INSTALL_DIR}"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

echo "Configuring ITK for macOS (arm64, Release)..."

# Notes:
# - Use ITK's internal Eigen (ITK_USE_SYSTEM_EIGEN=OFF) so the framework is self-contained.
# - Restrict to MPL2-only Eigen code (ITK_USE_EIGEN_MPL2_ONLY=ON).
# - Ensure both GDCM and DCMTK DICOM IO modules are enabled.
# - Install tree goes under ${INSTALL_DIR}.

cmake "${SRC_DIR}" \
  -G Xcode \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF \
  -DCMAKE_XCODE_ATTRIBUTE_LLVM_LTO=NO \
  -DCMAKE_XCODE_ATTRIBUTE_ENABLE_BITCODE=NO \
  -DCMAKE_C_FLAGS_RELEASE="-O3 -fno-lto" \
  -DCMAKE_CXX_FLAGS_RELEASE="-O3 -fno-lto" \
  -DBUILD_SHARED_LIBS=OFF \
  -DITK_BUILD_DEFAULT_MODULES=ON \
  -DITK_WRAP_PYTHON=OFF \
  -DBUILD_TESTING=OFF \
  -DITK_USE_BLAS=ON \
  -DVNL_USE_BLAS=ON \
  -DBLAS_LIBRARIES="-framework Accelerate" \
  -DLAPACK_LIBRARIES="-framework Accelerate" \
  -DITK_USE_SYSTEM_EIGEN=OFF \
  -DITK_USE_EIGEN_MPL2_ONLY=ON \
  -DModule_ITKGDCM=ON \
  -DModule_ITKDCMTK=ON \
  -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}"

echo
echo "Building ITK for macOS (Release)..."
cmake --build . --config Release -- -jobs 8

echo
echo "Installing ITK to ${INSTALL_DIR}..."
cmake --install . --config Release

echo
echo "Done."
echo "  Build tree:   ${BUILD_DIR}"
echo "  Install tree: ${INSTALL_DIR}"
