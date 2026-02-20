cmake_minimum_required(VERSION 3.14)
cmake_policy(SET CMP0175 NEW)

set(ARIEO_PACKAGE_CATEGORY "01_third_parties" CACHE INTERNAL "Category for Arieo packages")
set(ARIEO_PACKAGE_NAME "Arieo-ThirdParties" CACHE INTERNAL "Name of the Arieo package")
add_custom_target(${ARIEO_PACKAGE_NAME}
    DEPENDS 
        arieo_third_parties_conan_recipes
        arieo_third_parties_conan
        arieo_third_parties_gradle
)

set(CONAN_RECIPE_FILES
    ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/boost/conanfile.py
    ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/glfw/conanfile.py
    ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/mimalloc/conanfile.py
    ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/stb/conanfile.py
    ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/tinyobjloader/conanfile.py
    ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/vma/conanfile.py
    ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/wamr/conanfile.py
    ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/wasmtime/conanfile.py
)

##################################################################
# Check if Environment ARIEO_THIRDPARTIES_PACKAGES_OUTPUT_DIR is defined (set by install_py) and use it as the output directory for conan builds
if(NOT DEFINED ENV{ARIEO_THIRDPARTIES_PACKAGES_OUTPUT_DIR})
    message(STATUS "Environment variable ARIEO_THIRDPARTIES_PACKAGES_OUTPUT_DIR is not defined. Conan build output will be placed in ${CMAKE_BINARY_DIR}/conan_build_output")
    set(ARIEO_THIRDPARTIES_PACKAGES_OUTPUT_DIR ${CMAKE_BINARY_DIR})
else()
    message(STATUS "Using ARIEO_THIRDPARTIES_PACKAGES_OUTPUT_DIR: $ENV{ARIEO_THIRDPARTIES_PACKAGES_OUTPUT_DIR}")
    set(ARIEO_THIRDPARTIES_PACKAGES_OUTPUT_DIR $ENV{ARIEO_THIRDPARTIES_PACKAGES_OUTPUT_DIR})
endif()

set(ARIEO_CUR_PACKAGE_BUILD_OUTPUT_DIR ${ARIEO_THIRDPARTIES_PACKAGES_OUTPUT_DIR})

# Ensure output directory exists (configure_file doesn't create parent directories)
file(MAKE_DIRECTORY ${ARIEO_CUR_PACKAGE_BUILD_OUTPUT_DIR})

##################################################################
# Conan dependencies installation
# ARIEO_BUILD_CONFIGURE_PRESET is set by install_config.cmake included before this script
# Check if ARIEO_BUILD_CONFIGURE_PRESET is defined
if(NOT DEFINED ARIEO_BUILD_CONFIGURE_PRESET)
    message(FATAL_ERROR "Variable ARIEO_BUILD_CONFIGURE_PRESET is not defined.")
endif()

if(NOT DEFINED ENV{ARIEO_BUILD_ENV_PACKAGES_OUTPUT_DIR})
    message(FATAL_ERROR "Variable ARIEO_BUILD_ENV_PACKAGES_OUTPUT_DIR is not defined. It should be passed from the superbuild.")
endif()

if (${ARIEO_BUILD_CONFIGURE_PRESET} STREQUAL "android.armv8")
    set(conan_file ${CMAKE_CURRENT_LIST_DIR}/conan/conanfile.android.txt)
    set(conan_host_profile_file $ENV{ARIEO_BUILD_ENV_PACKAGES_OUTPUT_DIR}/conan/host/android.armv8/conan_host_profile.android.armv8.txt)
endif()

if (${ARIEO_BUILD_CONFIGURE_PRESET} STREQUAL "raspberry.armv8")
    set(conan_file ${CMAKE_CURRENT_LIST_DIR}/conan/conanfile.raspberry.txt)
    set(conan_host_profile_file $ENV{ARIEO_BUILD_ENV_PACKAGES_OUTPUT_DIR}/conan/host/raspberry.armv8/conan_host_profile.raspberry.armv8.txt)
endif()

if (${ARIEO_BUILD_CONFIGURE_PRESET} STREQUAL "ubuntu.x86_64")
    set(conan_file ${CMAKE_CURRENT_LIST_DIR}/conan/conanfile.ubuntu.txt)
    set(conan_host_profile_file $ENV{ARIEO_BUILD_ENV_PACKAGES_OUTPUT_DIR}/conan/host/ubuntu.x86_64/conan_host_profile.ubuntu.x86_64.txt)
endif()

# Add host profiles only for windows platform
if (${ARIEO_BUILD_CONFIGURE_PRESET} STREQUAL "windows.x86_64")
    if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")    
        set(conan_file ${CMAKE_CURRENT_LIST_DIR}/conan/conanfile.windows.txt)
        set(conan_host_profile_file $ENV{ARIEO_BUILD_ENV_PACKAGES_OUTPUT_DIR}/conan/host/windows.x86_64/conan_host_profile.windows.x86_64.txt)
    else()
        message(WARNING "Windows platform only support Windows host system.")
    endif()
endif()

# Add host profiles only for darwin platform

if (${ARIEO_BUILD_CONFIGURE_PRESET} STREQUAL "macos.arm64")
    if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
        set(conan_file ${CMAKE_CURRENT_LIST_DIR}/conan/conanfile.macos.txt)
        set(conan_host_profile_file $ENV{ARIEO_BUILD_ENV_PACKAGES_OUTPUT_DIR}/conan/host/macos.arm64/conan_host_profile.macos.arm64.txt)
    else()
        message(WARNING "macOS platform only supports Darwin host system.")
    endif()
endif()

if(DEFINED CONAN_RECIPE_FILES)
    set(CONAN_RECIPES_EXPORT_STAMP_FILE ${ARIEO_CUR_PACKAGE_BUILD_OUTPUT_DIR}/conan/${ARIEO_BUILD_CONFIGURE_PRESET}/.conan_recipes_export_complete)

    # If FORCE_EXPORT_RECIPES is set, delete the stamp file to force re-export
    if(DEFINED ENV{FORCE_EXPORT_RECIPES} AND "$ENV{FORCE_EXPORT_RECIPES}")
        message(STATUS "FORCE_EXPORT_RECIPES is set, forcing conan recipe export")
        file(REMOVE ${CONAN_RECIPES_EXPORT_STAMP_FILE})
    endif()

    add_custom_command(
        OUTPUT ${CONAN_RECIPES_EXPORT_STAMP_FILE}
        DEPENDS 
            ${CMAKE_CURRENT_LIST_DIR}/export_conan_recipes.cmake
            ${CONAN_RECIPE_FILES}
        COMMAND ${CMAKE_COMMAND} -E rm -f ${CONAN_RECIPES_EXPORT_STAMP_FILE}
        COMMAND ${CMAKE_COMMAND} -E echo "Exporting local conan recipes"
        COMMAND ${CMAKE_COMMAND}
            -P ${CMAKE_CURRENT_LIST_DIR}/export_conan_recipes.cmake
        COMMAND ${CMAKE_COMMAND} -E touch ${CONAN_RECIPES_EXPORT_STAMP_FILE}
        COMMENT "Exporting local conan recipes"
        USES_TERMINAL
        VERBATIM
    )

    add_custom_target(arieo_third_parties_conan_recipes ALL
        DEPENDS ${CONAN_RECIPES_EXPORT_STAMP_FILE}
    )
else()
    add_custom_target(arieo_third_parties_conan_recipes ALL
    )
endif()


if(DEFINED conan_host_profile_file AND DEFINED conan_file)
    # Use stamp files to track conan export/install completion (preset-specific)
    set(CONAN_INSTALL_STAMP_FILE ${ARIEO_CUR_PACKAGE_BUILD_OUTPUT_DIR}/conan/${ARIEO_BUILD_CONFIGURE_PRESET}/.conan_install_complete)

    # Use CONAN_BUILD env var if set, otherwise default to "missing"
    # Set CONAN_BUILD=* to force rebuild all packages
    if(DEFINED ENV{CONAN_BUILD})
        set(CONAN_BUILD_POLICY "$ENV{CONAN_BUILD}")
    else()
        set(CONAN_BUILD_POLICY "missing")
    endif()
    message(STATUS "Conan build policy: --build=${CONAN_BUILD_POLICY}")

    add_custom_command(
        OUTPUT ${CONAN_INSTALL_STAMP_FILE}
        DEPENDS 
            ${conan_host_profile_file}
            ${conan_file}
            ${CONAN_RECIPES_EXPORT_STAMP_FILE}
        COMMAND ${CMAKE_COMMAND} -E rm -f ${CONAN_INSTALL_STAMP_FILE}
        COMMAND ${CMAKE_COMMAND} -E echo "Running conan install for ${ARIEO_BUILD_CONFIGURE_PRESET}"
        COMMAND ${CMAKE_COMMAND} -E env CMAKE_POLICY_VERSION_MINIMUM=3.5
            conan
            install
            ${conan_file}
            --update
            --output-folder ${ARIEO_CUR_PACKAGE_BUILD_OUTPUT_DIR}/conan/${ARIEO_BUILD_CONFIGURE_PRESET}
            -pr:h=${conan_host_profile_file}
            --build=${CONAN_BUILD_POLICY}
        COMMAND ${CMAKE_COMMAND} -E touch ${CONAN_INSTALL_STAMP_FILE}
        COMMENT "Running conan install for ${ARIEO_BUILD_CONFIGURE_PRESET}"
        USES_TERMINAL
        VERBATIM
    )

    # This target will be built as part of ALL
    add_custom_target(arieo_third_parties_conan ALL
        DEPENDS ${CONAN_INSTALL_STAMP_FILE}
    )
else()
    message(WARNING "No matching preset found for ${ARIEO_BUILD_CONFIGURE_PRESET}. Conan install will be skipped.")
    # This target will be built as part of ALL
    add_custom_target(arieo_third_parties_conan ALL
    )
endif()



##################################################################
# Gradle dependencies installation
if(${ARIEO_BUILD_CONFIGURE_PRESET} STREQUAL "android.armv8")
    message(STATUS "Installing Gradle dependencies for preset: ${ARIEO_BUILD_CONFIGURE_PRESET}")
    set(gradle_executable "")

    if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
        set(gradle_executable ${CMAKE_CURRENT_LIST_DIR}/gradle/gradlew.bat)
    else()
        set(gradle_executable ${CMAKE_CURRENT_LIST_DIR}/gradle/gradlew)
    endif()

    # Check if gradlew.bat exists
    if(NOT EXISTS "${gradle_executable}")
        message(FATAL_ERROR "gradlew not found in ${gradle_executable}")
    endif()

    # Use a stamp file to track gradle installation completion (preset-specific)
    set(GRADLE_STAMP_FILE ${ARIEO_CUR_PACKAGE_BUILD_OUTPUT_DIR}/gradle/${ARIEO_BUILD_CONFIGURE_PRESET}/.gradle_install_complete)

    # Ensure the gradle directory exists
    file(MAKE_DIRECTORY ${ARIEO_CUR_PACKAGE_BUILD_OUTPUT_DIR}/gradle/${ARIEO_BUILD_CONFIGURE_PRESET})

    # Run gradle task
    add_custom_command(
        OUTPUT ${GRADLE_STAMP_FILE}
        DEPENDS 
            ${gradle_executable}
            ${CMAKE_CURRENT_LIST_DIR}/gradle/dependencies.gradle.kts
        COMMAND ${CMAKE_COMMAND} -E rm -f ${GRADLE_STAMP_FILE}
        COMMAND ${CMAKE_COMMAND} -E echo "Running gradle task for ${ARIEO_BUILD_CONFIGURE_PRESET}"
        COMMAND ${gradle_executable} generateCMakeConfigs
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            ${CMAKE_CURRENT_LIST_DIR}/gradle/build/cmake-configs/android/arm64-v8a/cmake
            ${ARIEO_CUR_PACKAGE_BUILD_OUTPUT_DIR}/gradle/${ARIEO_BUILD_CONFIGURE_PRESET}
        COMMAND ${CMAKE_COMMAND} -E touch ${GRADLE_STAMP_FILE}
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/gradle
        COMMENT "Running gradle task for ${ARIEO_BUILD_CONFIGURE_PRESET}"
        USES_TERMINAL
        VERBATIM
    )

    # This target will be built as part of ALL
    add_custom_target(arieo_third_parties_gradle ALL
        DEPENDS ${GRADLE_STAMP_FILE}
    )
else()
    message(STATUS "Skipping Gradle dependencies installation for preset: ${ARIEO_BUILD_CONFIGURE_PRESET}")
    add_custom_target(arieo_third_parties_gradle)
endif()

