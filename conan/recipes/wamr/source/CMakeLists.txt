# Custom CMakeLists.txt for building WAMR as a Conan package
# Builds two variants:
#   - iwasm     : release variant (fast interpreter, no debug overhead)
#   - iwasm_d   : debug variant (classic interpreter, source debugging, call stack dump)
#
# Uses WAMR's build-scripts/runtime_lib.cmake directly for cross-platform support

cmake_minimum_required(VERSION 3.14)

include(CheckPIESupported)

project(iwasm VERSION 2.4.4 LANGUAGES C CXX ASM)

option(BUILD_SHARED_LIBS "Build using shared libraries" OFF)

set(CMAKE_C_STANDARD 99)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_VERBOSE_MAKEFILE OFF)

# Reset default linker flags
set(CMAKE_SHARED_LIBRARY_LINK_C_FLAGS "")
set(CMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS "")

# WAMR_BUILD_PLATFORM and WAMR_BUILD_TARGET should be passed via cache variables
# from the Conan recipe (CMakeToolchain)

# Set WAMR root directory relative to the cloned source
set(WAMR_ROOT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/wamr)

# Public headers shared by both variants
set(WAMR_PUBLIC_HEADERS
    ${WAMR_ROOT_DIR}/core/iwasm/include/wasm_c_api.h
    ${WAMR_ROOT_DIR}/core/iwasm/include/wasm_export.h
    ${WAMR_ROOT_DIR}/core/iwasm/include/lib_export.h
)

check_pie_supported()

# Build both variants in separate directory scopes so that
# add_definitions() / include_directories() from runtime_lib.cmake
# do not leak between them.
add_subdirectory(release)
add_subdirectory(debug)
