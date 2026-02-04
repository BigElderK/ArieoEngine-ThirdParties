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
        OUTPUT_FOLDER
    )
    
    cmake_parse_arguments(
        ARGUMENT
        ""
        "${oneValueArgs}"
        ""
        ${ARGN}
    )

    execute_process(
        COMMAND conan
            install
            ${ARGUMENT_CONAN_FILE}
            --update
            --output-folder ${ARGUMENT_OUTPUT_FOLDER}
            -pr:h=${ARGUMENT_CONAN_HOST_PROFILE_FILE}
            --build=*
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

install_conan_file(
    CONAN_FILE ${CMAKE_CURRENT_LIST_DIR}/conan/conanfile.android.txt
    CONAN_HOST_PROFILE_FILE $ENV{VS_WORKSPACE}/00_build_env/conan/profiles/host/conan_host_profile.android.armv8.txt
    OUTPUT_FOLDER ${CMAKE_CURRENT_LIST_DIR}/conan/_generated/android/armv8
)

install_conan_file(
    CONAN_FILE ${CMAKE_CURRENT_LIST_DIR}/conan/conanfile.raspberry.txt
    CONAN_HOST_PROFILE_FILE $ENV{VS_WORKSPACE}/00_build_env/conan/profiles/host/conan_host_profile.raspberry.armv8.txt
    OUTPUT_FOLDER ${CMAKE_CURRENT_LIST_DIR}/conan/_generated/raspberry/armv8
)

install_conan_file(
    CONAN_FILE ${CMAKE_CURRENT_LIST_DIR}/conan/conanfile.ubuntu.txt
    CONAN_HOST_PROFILE_FILE $ENV{VS_WORKSPACE}/00_build_env/conan/profiles/host/conan_host_profile.ubuntu.x86_64.txt
    OUTPUT_FOLDER ${CMAKE_CURRENT_LIST_DIR}/conan/_generated/ubuntu/x86_64
)

if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
    install_conan_file(
        CONAN_FILE ${CMAKE_CURRENT_LIST_DIR}/conan/conanfile.windows.txt
        CONAN_HOST_PROFILE_FILE $ENV{VS_WORKSPACE}/00_build_env/conan/profiles/host/conan_host_profile.windows.x86_64.txt
        OUTPUT_FOLDER ${CMAKE_CURRENT_LIST_DIR}/conan/_generated/windows/x86_64
    )
endif()

if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
    install_conan_file(
        CONAN_FILE ${CMAKE_CURRENT_LIST_DIR}/conan/conanfile.macos.txt
        CONAN_HOST_PROFILE_FILE $ENV{VS_WORKSPACE}/00_build_env/conan/profiles/host/conan_host_profile.macos.arm64.txt
        OUTPUT_FOLDER ${CMAKE_CURRENT_LIST_DIR}/conan/_generated/macos/arm64
    )
endif()