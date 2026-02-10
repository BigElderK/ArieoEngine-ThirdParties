cmake_minimum_required(VERSION 3.14)
project(Arieo-ThirdParties)

##################################################################
# Conan dependencies installation
set(conan_host_profile_file "")
set(conan_file "")

# CMAKE_CONFIGURE_PRESET is set by install_config.cmake included before this script
# Check if CMAKE_CONFIGURE_PRESET is defined
if(NOT DEFINED CMAKE_CONFIGURE_PRESET)
    message(FATAL_ERROR "Variable CMAKE_CONFIGURE_PRESET is not defined. install_config.cmake should be included first.")
endif()

if(NOT DEFINED ARIEO_BUILDENV_PACKAGE_INSTALL_FOLDER)
    message(FATAL_ERROR "Variable ARIEO_BUILDENV_PACKAGE_INSTALL_FOLDER is not defined. It should be passed from the superbuild.")
endif()

if (${CMAKE_CONFIGURE_PRESET} STREQUAL "android.armv8")
    set(conan_file ${CMAKE_CURRENT_LIST_DIR}/conan/conanfile.android.txt)
    set(conan_host_profile_file ${ARIEO_BUILDENV_PACKAGE_INSTALL_FOLDER}/conan/host/android.armv8/conan_host_profile.android.armv8.txt)
endif()

if (${CMAKE_CONFIGURE_PRESET} STREQUAL "raspberry.armv8")
    set(conan_file ${CMAKE_CURRENT_LIST_DIR}/conan/conanfile.raspberry.txt)
    set(conan_host_profile_file ${ARIEO_BUILDENV_PACKAGE_INSTALL_FOLDER}/conan/host/raspberry.armv8/conan_host_profile.raspberry.armv8.txt)
endif()

if (${CMAKE_CONFIGURE_PRESET} STREQUAL "ubuntu.x86_64")
    set(conan_file ${CMAKE_CURRENT_LIST_DIR}/conan/conanfile.ubuntu.txt)
    set(conan_host_profile_file ${ARIEO_BUILDENV_PACKAGE_INSTALL_FOLDER}/conan/host/ubuntu.x86_64/conan_host_profile.ubuntu.x86_64.txt)
endif()

# Add host profiles only for windows platform
if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
    if (${CMAKE_CONFIGURE_PRESET} STREQUAL "windows.x86_64")
        set(conan_file ${CMAKE_CURRENT_LIST_DIR}/conan/conanfile.windows.txt)
        set(conan_host_profile_file ${ARIEO_BUILDENV_PACKAGE_INSTALL_FOLDER}/conan/host/windows.x86_64/conan_host_profile.windows.x86_64.txt)
    endif()
else()
    #message(FATAL_ERROR "Windows platform only support Windows host system.")
endif()

# Add host profiles only for darwin platform
if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
    if (${CMAKE_CONFIGURE_PRESET} STREQUAL "macos.arm64")
        set(conan_file ${CMAKE_CURRENT_LIST_DIR}/conan/conanfile.macos.txt)
        set(conan_host_profile_file ${ARIEO_BUILDENV_PACKAGE_INSTALL_FOLDER}/conan/host/macos.arm64/conan_host_profile.macos.arm64.txt)
    endif()
else()
    #message(FATAL_ERROR "macOS platform only supports Darwin host system.")
endif()

# Use a stamp file to track conan installation completion (preset-specific)
set(CONAN_STAMP_FILE ${CMAKE_BINARY_DIR}/conan/host/${CMAKE_CONFIGURE_PRESET}/.conan_install_complete)

# Ensure the conan directory exists
file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/conan/host/${CMAKE_CONFIGURE_PRESET})

add_custom_command(
    OUTPUT ${CONAN_STAMP_FILE}
    DEPENDS 
        ${conan_host_profile_file}
        ${conan_file}
    COMMAND ${CMAKE_COMMAND} -E echo "Running conan install for ${CMAKE_CONFIGURE_PRESET}"
    COMMAND conan
        install
        ${conan_file}
        --update
        --output-folder ${CMAKE_BINARY_DIR}/conan/${CMAKE_CONFIGURE_PRESET}
        -pr:h=${conan_host_profile_file}
        --build=missing # change to --build=* to force rebuild of all packages
    COMMAND ${CMAKE_COMMAND} -E touch ${CONAN_STAMP_FILE}
    COMMENT "Running conan install for ${CMAKE_CONFIGURE_PRESET}"
    COMMAND_ERROR_IS_FATAL ANY
    USES_TERMINAL
    VERBATIM
)

# This target will be built as part of ALL
add_custom_target(arieo_third_parties_conan ALL
    DEPENDS ${CONAN_STAMP_FILE}
)

# Install conan generated files
install(DIRECTORY ${CMAKE_BINARY_DIR}/conan/${CMAKE_CONFIGURE_PRESET}/
    DESTINATION conan/${CMAKE_CONFIGURE_PRESET}
)

##################################################################
# Gradle dependencies installation
if(${CMAKE_CONFIGURE_PRESET} STREQUAL "android.armv8")
    message(STATUS "Installing Gradle dependencies for preset: ${CMAKE_CONFIGURE_PRESET}")
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
    set(GRADLE_STAMP_FILE ${CMAKE_BINARY_DIR}/gradle/host/${CMAKE_CONFIGURE_PRESET}/.gradle_install_complete)

    # Ensure the gradle directory exists
    file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/gradle/host/${CMAKE_CONFIGURE_PRESET})

    # Run gradle task
    add_custom_command(
        OUTPUT ${GRADLE_STAMP_FILE}
        DEPENDS 
            ${gradle_executable}
            ${CMAKE_CURRENT_LIST_DIR}/gradle/dependencies.gradle.kts
        COMMAND ${CMAKE_COMMAND} -E echo "Running gradle task for ${CMAKE_CONFIGURE_PRESET}"
        COMMAND ${gradle_executable} generateCMakeConfigs
        COMMAND ${CMAKE_COMMAND} -E touch ${GRADLE_STAMP_FILE}
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/gradle
        COMMENT "Running gradle task for ${CMAKE_CONFIGURE_PRESET}"
        COMMAND_ERROR_IS_FATAL ANY
        USES_TERMINAL
        VERBATIM
    )

    # This target will be built as part of ALL
    add_custom_target(arieo_third_parties_gradle ALL
        DEPENDS ${GRADLE_STAMP_FILE}
    )

    # Install gradle generated files directly from build output
    install(DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/gradle/build/cmake-configs/android/arm64-v8a/cmake/
        DESTINATION gradle/${CMAKE_CONFIGURE_PRESET}
    )
else()
    message(STATUS "Skipping Gradle dependencies installation for preset: ${CMAKE_CONFIGURE_PRESET}")
endif()

