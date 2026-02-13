# Release variant: fast interpreter, no debug features
# Produces libiwasm.a (or iwasm.lib on Windows)
#
# Uses cache variables from Conan toolchain as-is (WAMR_BUILD_FAST_INTERP, etc.)
# No debug-specific flags are set here.

include(${WAMR_ROOT_DIR}/build-scripts/runtime_lib.cmake)

add_library(vmlib ${WAMR_RUNTIME_LIB_SOURCE})

target_include_directories(vmlib INTERFACE
    $<INSTALL_INTERFACE:include>
)

set_target_properties(vmlib PROPERTIES
    OUTPUT_NAME iwasm
    PUBLIC_HEADER "${WAMR_PUBLIC_HEADERS}"
    POSITION_INDEPENDENT_CODE ON
)

# Platform-specific link libraries
if(CMAKE_SYSTEM_NAME STREQUAL "Linux" OR CMAKE_SYSTEM_NAME STREQUAL "Android")
    target_link_libraries(vmlib ${LLVM_AVAILABLE_LIBS} ${UV_A_LIBS} -lm -ldl -lpthread)
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    target_link_libraries(vmlib ${LLVM_AVAILABLE_LIBS} ${UV_A_LIBS})
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    target_link_libraries(vmlib ${LLVM_AVAILABLE_LIBS} ${UV_A_LIBS})
endif()

install(TARGETS vmlib
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
    PUBLIC_HEADER DESTINATION include
)
