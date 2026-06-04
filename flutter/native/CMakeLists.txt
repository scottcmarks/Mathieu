# Builds libmathieu_engine.so (Android / Linux) and mathieu_engine.dll (Windows)
# from the shared C++ M12 engine + the FFI shim.
cmake_minimum_required(VERSION 3.10)
project(mathieu_engine LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(MATHIEU_PI "${CMAKE_CURRENT_SOURCE_DIR}/../../PlatformIndependent")
if(EXISTS "$ENV{HOME}/Toolbox/PlatformIndependent")
  set(TOOLBOX "$ENV{HOME}/Toolbox/PlatformIndependent")
else()
  set(TOOLBOX "${CMAKE_CURRENT_SOURCE_DIR}/../../../Toolbox/PlatformIndependent")
endif()

set(SOURCES
  "${CMAKE_CURRENT_SOURCE_DIR}/mathieu_ffi.cpp"
  "${MATHIEU_PI}/M12/Permutation/m12.cc"
  "${TOOLBOX}/rand_utils.c"
)

# Windows needs an arc4random shim (Android/Linux have it in libc).
if(WIN32)
  list(APPEND SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/win32_compat.c")
endif()

add_library(mathieu_engine SHARED ${SOURCES})

target_include_directories(mathieu_engine PRIVATE
  "${MATHIEU_PI}/Permutation"
  "${MATHIEU_PI}/M12/Permutation"
  "${CMAKE_CURRENT_SOURCE_DIR}"
  "${TOOLBOX}"
  "${TOOLBOX}/Permutation"
)

# Old C++; silence its warnings rather than fail the host/NDK build.
target_compile_options(mathieu_engine PRIVATE -w)
set_target_properties(mathieu_engine PROPERTIES C_VISIBILITY_PRESET default CXX_VISIBILITY_PRESET default)
