cmake_minimum_required(VERSION 3.20)

# INSTALL_FOLDER must be set from command line or environment variable
if(NOT DEFINED INSTALL_FOLDER)
    # Try to get from environment variable
    if(DEFINED ENV{INSTALL_FOLDER})
        set(INSTALL_FOLDER "$ENV{INSTALL_FOLDER}")
        message(STATUS "Using INSTALL_FOLDER from environment: ${INSTALL_FOLDER}")
    else()
        message(FATAL_ERROR "INSTALL_FOLDER is not defined. Please specify it with -DINSTALL_FOLDER=<path> or set INSTALL_FOLDER environment variable")
    endif()
else()
    message(STATUS "Using INSTALL_FOLDER from command line: ${INSTALL_FOLDER}")
endif()

message(STATUS "Installing third-party dependencies...")

# Install dependencies from Conan
message(STATUS "Installing Conan dependencies...")
execute_process(
    COMMAND ${CMAKE_COMMAND} -P install_from_conan.cmake
    WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
    RESULT_VARIABLE CONAN_RESULT
)

if(NOT CONAN_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to install Conan dependencies")
endif()

message(STATUS "Conan dependencies installed successfully")

# Install dependencies from Gradle
message(STATUS "Installing Gradle dependencies...")
execute_process(
    COMMAND ${CMAKE_COMMAND} -P install_from_gradle.cmake
    WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
    RESULT_VARIABLE GRADLE_RESULT
)

if(NOT GRADLE_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to install Gradle dependencies")
endif()

message(STATUS "Gradle dependencies installed successfully")
message(STATUS "All third-party dependencies installed successfully")
