#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${ROOT_DIR}"
BUILD_DIR="${ROOT_DIR}/build-visionos-sim"
INSTALL_DIR="${ROOT_DIR}/install-visionos-sim"

# Clean build dir so flag/module changes actually apply
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

# Cache file to satisfy CMake try_run() in cross-compile mode (visionOS sim)
CACHE_FILE="${BUILD_DIR}/InitialCache_visionos_sim.cmake"

cat > "${CACHE_FILE}" << 'CACHE_EOF'
# Pre-fill results for cross-compilation so try_run() doesn't fail.

# double-conversion: assume operations are correct
set(DOUBLE_CONVERSION_CORRECT_DOUBLE_OPERATIONS 1 CACHE STRING "double-conversion behaves correctly" FORCE)

# VNL large file support: not needed on visionOS
set(VCL_HAS_LFS 0 CACHE STRING "no large file support needed on visionOS" FORCE)

# libc++ detection: pretend try_run succeeded and libc++ is recent
set(_libcxx_run_result 0 CACHE STRING "pretend try_run succeeded" FORCE)
set(_using_libcxx 1 CACHE STRING "use libc++" FORCE)
set(_libcxx_version 1102 CACHE STRING "libc++ version (>= 1102)" FORCE)

# Quiet-NaN 22nd bit (NrrdIO / Teem)
set(QNANHIBIT_VALUE "1" CACHE STRING "Result of try_run for 22nd bit of 32-bit quiet-NaN" FORCE)
set(QNANHIBIT_VALUE__TRYRUN_OUTPUT "" CACHE STRING "Output of try_run for 22nd bit of 32-bit quiet-NaN" FORCE)
CACHE_EOF

echo "Configuring ITK for visionOS (simulator, arm64)..."
cmake "${SRC_DIR}" \
  -C "${CACHE_FILE}" \
  -G Xcode \
  -DCMAKE_SYSTEM_NAME=visionOS \
  -DCMAKE_OSX_SYSROOT=xrsimulator \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=OFF \
  -DITK_BUILD_DEFAULT_MODULES=ON \
  -DITK_WRAP_PYTHON=OFF \
  -DModule_ITKTestKernel=OFF \
  -DBUILD_TESTING=OFF \
  -DModule_ITKMINC=ON \
  -DModule_ITKMINC2=ON \
  -DModule_ITKIOGDCM=ON \
  -DModule_ITKDCMTK=ON \
  -DITK_USE_BLAS=ON \
  -DVNL_USE_BLAS=ON \
  -DBLAS_LIBRARIES="-framework Accelerate" \
  -DLAPACK_LIBRARIES="-framework Accelerate" \
  -DITK_USE_SYSTEM_EIGEN=OFF \
  -DDOUBLE_CONVERSION_CORRECT_DOUBLE_OPERATIONS:BOOL=ON \
  -DDOUBLE_CONVERSION_CORRECT_DOUBLE_OPERATIONS__TRYRUN_OUTPUT:STRING="" \
  -DVCL_HAS_LFS:BOOL=ON \
  -DVCL_HAS_LFS__TRYRUN_OUTPUT:STRING="" \
  -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF \
  -DCMAKE_XCODE_ATTRIBUTE_LLVM_LTO=NO \
  -DCMAKE_XCODE_ATTRIBUTE_ENABLE_BITCODE=NO \
  -DCMAKE_C_FLAGS_RELEASE="-fno-lto" \
  -DCMAKE_CXX_FLAGS_RELEASE="-fno-lto"

echo "Building ITK for visionOS (simulator, Release)…"
cmake --build . --config Release -- -jobs 8

echo
echo "Installing ITK for visionOS (simulator) into:"
echo "  ${INSTALL_DIR}"
rm -rf "${INSTALL_DIR}"
cmake --install . --config Release --prefix "${INSTALL_DIR}"

echo
echo "✅ Done."
echo "  Build   dir: ${BUILD_DIR}"
echo "  Install dir: ${INSTALL_DIR}"
