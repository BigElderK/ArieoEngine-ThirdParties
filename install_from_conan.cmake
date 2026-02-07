cmake_minimum_required(VERSION 3.20)

function(export_conan_recipes)
    set(multiValueArgs
        CONAN_RECIPE_FILES
    )
    cmake_parse_arguments(
        ARGUMENT
        ""
        "${oneValueArgs}"
        "${multiValueArgs}"
        ${ARGN}
    )

    # print arguments and exit for debugging now
    message(STATUS "CONAN_RECIPE_FILES: ${ARGUMENT_CONAN_RECIPE_FILES}")

    foreach(RECIPE_FILE IN LISTS ARGUMENT_CONAN_RECIPE_FILES)
        get_filename_component(RECIPE_DIR ${RECIPE_FILE} DIRECTORY)
        execute_process(
            COMMAND conan
                export ${RECIPE_DIR}
                --user=arieo
                --channel=dev
            RESULT_VARIABLE CONAN_RESULT
            ECHO_OUTPUT_VARIABLE    # This shows output in real time
            ECHO_ERROR_VARIABLE     # This shows errors in real time
            COMMAND_ECHO STDOUT      # Echo the command being executed
        )
        
        if(NOT CONAN_RESULT EQUAL 0)
            message(FATAL_ERROR "Conan execute failed")
            exit(1)
        endif()
    endforeach()
endfunction()

function(install_conan_file)
    set(oneValueArgs
        CONAN_FILE
        CONAN_HOST_PROFILE_FILE
        INSTALL_FOLDER
    )
    
    cmake_parse_arguments(
        ARGUMENT
        ""
        "${oneValueArgs}"
        ""
        ${ARGN}
    )

    # print arguments and exit for now
    message(STATUS "CONAN_FILE: ${ARGUMENT_CONAN_FILE}")
    message(STATUS "CONAN_HOST_PROFILE_FILE: ${ARGUMENT_CONAN_HOST_PROFILE_FILE}")
    message(STATUS "INSTALL_FOLDER: ${ARGUMENT_INSTALL_FOLDER}")
    # Clean install folder before any operations
    if(EXISTS "${ARGUMENT_INSTALL_FOLDER}")
        message(STATUS "Cleaning install folder: ${ARGUMENT_INSTALL_FOLDER}")
        file(REMOVE_RECURSE "${ARGUMENT_INSTALL_FOLDER}")
    endif()
    file(MAKE_DIRECTORY "${ARGUMENT_INSTALL_FOLDER}")
    
    execute_process(
        COMMAND conan
            install
            ${ARGUMENT_CONAN_FILE}
            --update
            --output-folder ${ARGUMENT_INSTALL_FOLDER}
            -pr:h=${ARGUMENT_CONAN_HOST_PROFILE_FILE}
            --build=missing # change to --build=* to force rebuild of all packages
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
        RESULT_VARIABLE CONAN_RESULT
        ECHO_OUTPUT_VARIABLE    # This shows output in real time
        ECHO_ERROR_VARIABLE     # This shows errors in real time
        COMMAND_ECHO STDOUT      # Echo the command being executed
    )
    
    if(NOT CONAN_RESULT EQUAL 0)
        message(FATAL_ERROR "Conan execute failed")
        exit(1)
    endif()
endfunction()

#Glob all conanfile.py from subfolders in conan/recipes
file(GLOB_RECURSE GLOB_CONAN_RECIPE_FILES
    ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/*/conanfile.py
)

export_conan_recipes(
    CONAN_RECIPE_FILES ${GLOB_CONAN_RECIPE_FILES}
)

if($ENV{ARIEO_PACKAGE_BUILD_SETTING_HOST_PRESET} STREQUAL "android.armv8")
    install_conan_file(
        CONAN_FILE ${CMAKE_CURRENT_LIST_DIR}/conan/conanfile.android.txt
        CONAN_HOST_PROFILE_FILE $ENV{ARIEO_PACKAGE_BUILDENV_INSTALL_FOLDER}/conan/host/android.armv8/conan_host_profile.android.armv8.txt
        INSTALL_FOLDER $ENV{ARIEO_CUR_PACKAGE_INSTALL_FOLDER}/conan/$ENV{ARIEO_PACKAGE_BUILD_SETTING_HOST_PRESET}
    )
endif()

if($ENV{ARIEO_PACKAGE_BUILD_SETTING_HOST_PRESET} STREQUAL "raspberry.armv8")
    install_conan_file(
        CONAN_FILE ${CMAKE_CURRENT_LIST_DIR}/conan/conanfile.raspberry.txt
        CONAN_HOST_PROFILE_FILE $ENV{ARIEO_PACKAGE_BUILDENV_INSTALL_FOLDER}/conan/host/raspberry.armv8/conan_host_profile.raspberry.armv8.txt
        INSTALL_FOLDER $ENV{ARIEO_CUR_PACKAGE_INSTALL_FOLDER}/conan/$ENV{ARIEO_PACKAGE_BUILD_SETTING_HOST_PRESET}
    )
endif()

if($ENV{ARIEO_PACKAGE_BUILD_SETTING_HOST_PRESET} STREQUAL "ubuntu.x86_64")
    install_conan_file(
        CONAN_FILE ${CMAKE_CURRENT_LIST_DIR}/conan/conanfile.ubuntu.txt
        CONAN_HOST_PROFILE_FILE $ENV{ARIEO_PACKAGE_BUILDENV_INSTALL_FOLDER}/conan/host/ubuntu.x86_64/conan_host_profile.ubuntu.x86_64.txt
        INSTALL_FOLDER $ENV{ARIEO_CUR_PACKAGE_INSTALL_FOLDER}/conan/$ENV{ARIEO_PACKAGE_BUILD_SETTING_HOST_PRESET}
    )
endif()

if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
    if($ENV{ARIEO_PACKAGE_BUILD_SETTING_HOST_PRESET} STREQUAL "windows.x86_64")
        install_conan_file(
            CONAN_FILE ${CMAKE_CURRENT_LIST_DIR}/conan/conanfile.windows.txt
            CONAN_HOST_PROFILE_FILE $ENV{ARIEO_PACKAGE_BUILDENV_INSTALL_FOLDER}/conan/host/windows.x86_64/conan_host_profile.windows.x86_64.txt
            INSTALL_FOLDER $ENV{ARIEO_CUR_PACKAGE_INSTALL_FOLDER}/conan/$ENV{ARIEO_PACKAGE_BUILD_SETTING_HOST_PRESET}
        )
    endif()
endif()

if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
    if($ENV{ARIEO_PACKAGE_BUILD_SETTING_HOST_PRESET} STREQUAL "macos.arm64")
        install_conan_file(
            CONAN_FILE ${CMAKE_CURRENT_LIST_DIR}/conan/conanfile.macos.txt
            CONAN_HOST_PROFILE_FILE $ENV{ARIEO_PACKAGE_BUILDENV_INSTALL_FOLDER}/conan/host/macos.arm64/conan_host_profile.macos.arm64.txt
            INSTALL_FOLDER $ENV{ARIEO_CUR_PACKAGE_INSTALL_FOLDER}/conan/$ENV{ARIEO_PACKAGE_BUILD_SETTING_HOST_PRESET}
        )
    endif()
endif()