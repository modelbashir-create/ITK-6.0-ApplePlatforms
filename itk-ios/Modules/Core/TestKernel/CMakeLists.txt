if(CMAKE_SYSTEM_NAME STREQUAL "iOS")
  message(STATUS "Skipping ITKTestKernel module on iOS (no test driver install needed)")
  return()
endif()

project(ITKTestKernel)
set(ITKTestKernel_LIBRARIES ITKTestKernel)
itk_module_impl()