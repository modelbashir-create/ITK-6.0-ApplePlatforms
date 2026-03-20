# Minimal TestKernel CMakeLists for ITKvision (visionOS only)
# We skip building/installing itkTestDriver on visionOS because
# MACOSX_BUNDLE install rules cause CMake errors in cross-compiling.

if(APPLE AND CMAKE_SYSTEM_NAME STREQUAL "visionOS")
  message(STATUS "Skipping itkTestDriver for visionOS (TestKernel disabled).")
  return()
endif()

# For other platforms in this tree we don't define anything.
# (If you ever want full TestKernel here, restore
#  CMakeLists_TestKernel_backup_vision.txt.)