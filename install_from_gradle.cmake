cmake_minimum_required(VERSION 3.20)

if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
    set(CMAKE_HOST_BATCH_SUFFIX .bat)
else()
    set(CMAKE_HOST_BATCH_SUFFIX .sh)
endif()

function(install_gradle)
    set(oneValueArgs
        GRADLE_FILE
        GRADLE_TASK
        OUTPUT_FOLDER
        WORKING_DIRECTORY
    )
    
    cmake_parse_arguments(
        ARGUMENT
        ""
        "${oneValueArgs}"
        ""
        ${ARGN}
    )

    # Check if gradlew.bat exists
    if(NOT EXISTS "${ARGUMENT_WORKING_DIRECTORY}/gradlew.bat")
        message(FATAL_ERROR "gradlew.bat not found in ${ARGUMENT_WORKING_DIRECTORY}")
    endif()

    # Now run the actual build
    message(STATUS "Running Gradle build...")
    execute_process(
        COMMAND ${ARGUMENT_GRADLE_FILE} ${ARGUMENT_GRADLE_TASK}
        WORKING_DIRECTORY ${ARGUMENT_WORKING_DIRECTORY}
        RESULT_VARIABLE GRADLE_RESULT
        OUTPUT_VARIABLE gradle_output
        ERROR_VARIABLE gradle_error
        ECHO_OUTPUT_VARIABLE    # This shows output in real time
        ECHO_ERROR_VARIABLE     # This shows errors in real time
        COMMAND_ECHO STDOUT      # Echo the command being executed
    )
    
    if(NOT GRADLE_RESULT EQUAL 0)
        message(STATUS "Gradle output: ${gradle_output}")
        message(STATUS "Gradle error: ${gradle_error}")
        message(FATAL_ERROR "Gradle build failed with exit code: ${GRADLE_RESULT}")
    endif()

    # Copy all cmake files under build/cmake-configs to OUTPOUT folder
    set(SOURCE_FOLDER "${ARGUMENT_WORKING_DIRECTORY}/build/cmake-configs")
    if(EXISTS "${SOURCE_FOLDER}")
        file(MAKE_DIRECTORY "${ARGUMENT_OUTPUT_FOLDER}")
        file(COPY "${SOURCE_FOLDER}/" DESTINATION "${ARGUMENT_OUTPUT_FOLDER}")
        message(STATUS "Copied cmake-configs to ${ARGUMENT_OUTPUT_FOLDER}")
    else()
        message(FATAL_ERROR "Source folder ${SOURCE_FOLDER} does not exist.")
    endif()

endfunction()

if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
    install_gradle(
        GRADLE_FILE ${CMAKE_CURRENT_LIST_DIR}/gradle/gradlew.bat
        GRADLE_TASK generateCMakeConfigs
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/gradle
        OUTPUT_FOLDER ${CMAKE_CURRENT_LIST_DIR}/gradle/_generated
    )
else()
    install_gradle(
        GRADLE_FILE ${CMAKE_CURRENT_LIST_DIR}/gradle/gradlew
        GRADLE_TASK generateCMakeConfigs
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/gradle
        OUTPUT_FOLDER ${CMAKE_CURRENT_LIST_DIR}/gradle/_generated
    )
endif()