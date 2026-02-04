cmake_minimum_required(VERSION 3.20)

function(install_conan_recipe)
    set(oneValueArgs
        CONAN_RECIPE_FILE
        CONAN_HOST_PROFILE
        OUTPUT_FOLDER
    )
    
    cmake_parse_arguments(
        ARGUMENT
        ""
        "${oneValueArgs}"
        ""
        ${ARGN}
    )

    # export conan package from recipe file
    # get the parent folder of the recipe file
    get_filename_component(RECIPE_DIR ${ARGUMENT_CONAN_RECIPE_FILE} DIRECTORY)
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

    # install conan package from recipe file
    # execute_process(
    #     COMMAND conan
    #         create ${ARGUMENT_CONAN_RECIPE_FILE}
    #         -pr:h=${ARGUMENT_CONAN_HOST_PROFILE}
    #         # --output-folder ${ARGUMENT_OUTPUT_FOLDER}
    #         --build=never
    #         --user=arieo
    #         --channel=dev
    #     RESULT_VARIABLE CONAN_RESULT
    #     ECHO_OUTPUT_VARIABLE    # This shows output in real time
    #     ECHO_ERROR_VARIABLE     # This shows errors in real time
    #     COMMAND_ECHO STDOUT      # Echo the command being executed
    # )
    
    # if(NOT CONAN_RESULT EQUAL 0)
    #     message(FATAL_ERROR "Conan execute failed")
    #     exit(1)
    # endif()
endfunction()

function(install_conan_recipes)
    set(oneValueArgs
        CONAN_HOST_PROFILE
        OUTPUT_FOLDER
    )

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
        install_conan_recipe(
            CONAN_RECIPE_FILE ${RECIPE_FILE}
            CONAN_HOST_PROFILE ${ARGUMENT_CONAN_HOST_PROFILE}
            OUTPUT_FOLDER ${ARGUMENT_OUTPUT_FOLDER}
        )
    endforeach()

endfunction()

# install conan recipes for android.armv8
install_conan_recipes(
    CONAN_HOST_PROFILE ${CMAKE_CURRENT_LIST_DIR}/../00_build_env/conan/profiles/host/conan_host_profile.android.armv8.txt
    OUTPUT_FOLDER ${CMAKE_CURRENT_LIST_DIR}/conan/_generated/android/armv8
    CONAN_RECIPE_FILES 
        # ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/boost/conanfile.py
        # ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/glfw/conanfile.py
        ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/mimalloc/conanfile.py
        # ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/stb/conanfile.py
        # ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/tinyobjloader/conanfile.py
        # ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/vma/conanfile.py
)

# # install conan recipes for ubuntu.x86_64
# install_conan_recipes(
#     CONAN_HOST_PROFILE ${CMAKE_CURRENT_LIST_DIR}/../00_build_env/conan/profiles/host/conan_host_profile.ubuntu.x86_64.txt
#     OUTPUT_FOLDER ${CMAKE_CURRENT_LIST_DIR}/conan/_generated/ubuntu/x86_64
#     CONAN_RECIPE_FILES 
#         ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/boost/conanfile.py
#         # ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/glfw/conanfile.py
#         ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/mimalloc/conanfile.py
#         ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/stb/conanfile.py
#         ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/tinyobjloader/conanfile.py
#         ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/vma/conanfile.py
# )

# # install conan recipes for raspberry.armv8
# install_conan_recipes(
#     CONAN_HOST_PROFILE ${CMAKE_CURRENT_LIST_DIR}/../00_build_env/conan/profiles/host/conan_host_profile.raspberry.armv8.txt
#     OUTPUT_FOLDER ${CMAKE_CURRENT_LIST_DIR}/conan/_generated/raspberry/armv8
#     CONAN_RECIPE_FILES 
#         ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/boost/conanfile.py
#         # ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/glfw/conanfile.py
#         ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/mimalloc/conanfile.py
#         ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/stb/conanfile.py
#         ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/tinyobjloader/conanfile.py
#         ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/vma/conanfile.py
# )


# if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
#     # install conan recipes for windows.x86_64
#     install_conan_recipes(
#         CONAN_HOST_PROFILE ${CMAKE_CURRENT_LIST_DIR}/../00_build_env/conan/profiles/host/conan_host_profile.windows.x86_64.txt
#         OUTPUT_FOLDER ${CMAKE_CURRENT_LIST_DIR}/conan/_generated/windows/x86_64
#         CONAN_RECIPE_FILES 
#             ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/boost/conanfile.py
#             ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/glfw/conanfile.py
#             ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/mimalloc/conanfile.py
#             ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/stb/conanfile.py
#             ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/tinyobjloader/conanfile.py
#             ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/vma/conanfile.py
#     )
# endif()

# if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
#     # install conan recipes for macos.armv8
#     install_conan_recipes(
#         CONAN_HOST_PROFILE ${CMAKE_CURRENT_LIST_DIR}/../00_build_env/conan/profiles/host/conan_host_profile.macos.armv8.txt
#         OUTPUT_FOLDER ${CMAKE_CURRENT_LIST_DIR}/conan/_generated/macos/armv8
#         CONAN_RECIPE_FILES 
#             ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/boost/conanfile.py
#             ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/glfw/conanfile.py
#             ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/mimalloc/conanfile.py
#             ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/stb/conanfile.py
#             ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/tinyobjloader/conanfile.py
#             ${CMAKE_CURRENT_LIST_DIR}/conan/recipes/vma/conanfile.py
#     )
# endif()