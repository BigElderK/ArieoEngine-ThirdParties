# Debug variant: classic interpreter with source debugging features
# Produces libiwasm_d.a (or iwasm_d.lib on Windows)
#
# Overrides cache variables from Conan toolchain to enable debug features:
#   - Classic interpreter (fast_interp OFF, required by debug_interp)
#   - GDB-compatible debug server for LLDB to attach (debug_interp)
#   - AOT source-level debugging (debug_aot)
#   - Call stack dump on exceptions (dump_call_stack)
#   - Function name section for readable stack traces (custom_name_section)
#   - AOT stack frames for stack inspection (aot_stack_frame)

# Shadow cache variables with local overrides for debug features
set(WAMR_BUILD_FAST_INTERP 0)
set(WAMR_BUILD_DEBUG_INTERP 1)
set(WAMR_BUILD_DEBUG_AOT 1)
set(WAMR_BUILD_DUMP_CALL_STACK 1)
set(WAMR_BUILD_CUSTOM_NAME_SECTION 1)
set(WAMR_BUILD_AOT_STACK_FRAME 1)

include(${WAMR_ROOT_DIR}/build-scripts/runtime_lib.cmake)

add_library(vmlib_debug ${WAMR_RUNTIME_LIB_SOURCE})

target_include_directories(vmlib_debug INTERFACE
    $<INSTALL_INTERFACE:include>
)

set_target_properties(vmlib_debug PROPERTIES
    OUTPUT_NAME iwasm_d
    POSITION_INDEPENDENT_CODE ON
)

# Platform-specific link libraries
if(CMAKE_SYSTEM_NAME STREQUAL "Linux" OR CMAKE_SYSTEM_NAME STREQUAL "Android")
    target_link_libraries(vmlib_debug ${LLVM_AVAILABLE_LIBS} ${UV_A_LIBS} -lm -ldl -lpthread)
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    target_link_libraries(vmlib_debug ${LLVM_AVAILABLE_LIBS} ${UV_A_LIBS})
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    target_link_libraries(vmlib_debug ${LLVM_AVAILABLE_LIBS} ${UV_A_LIBS})
endif()

install(TARGETS vmlib_debug
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
)
