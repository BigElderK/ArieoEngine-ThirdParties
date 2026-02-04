import logging
from conan import ConanFile
from conan.tools.cmake import CMake, CMakeToolchain, CMakeDeps, cmake_layout
from conan.tools.scm import Git
from conan.tools.files import rmdir
from conan.tools.microsoft import MSBuild
from conan.tools.files import copy
import os
import re

class MiMallocConan(ConanFile):
    name = "mimalloc"
    version = "3.1.5"
    settings = "os", "arch", "build_type"

    options = {"shared": [True, False], "fPIC": [True, False], "secure": [True, False]}
    default_options = {"shared": False, "fPIC": True, "secure": False}
    
    # default_user = "bigelderk"
    # default_channel = "default"

    def layout(self):
        cmake_layout(self, src_folder="./source", build_folder=os.path.join("./build", str(self.settings.os), str(self.settings.arch)))

    def source(self):
        self.run("git clone https://github.com/microsoft/mimalloc.git --branch v%s --depth=1" % (self.version)) 

        # # Read the content of internal.h
        # patch_head_file = os.path.join(self.source_folder, 'mimalloc', 'include', 'mimalloc', 'internal.h')
        # with open(patch_head_file, 'r') as file:
        #     content = file.read()

        # # Define the regex pattern to match the line (allowing variable whitespace)
        # pattern = r'^\s*#define\s+mi_decl_thread\s+__thread\s*$'
        # replacement = '#define mi_decl_thread          __attribute__((visibility("default"))) __attribute__((aligned(64))) __thread'
        # # Perform the replacement using regex (multiline mode)
        # content = re.sub(pattern, replacement, content, flags=re.MULTILINE)

        # # Define the regex pattern to match the line (allowing variable whitespace)
        # pattern = r'#define mi_decl_hidden\s+__attribute__\(\(visibility\("hidden"\)\)\)'
        # replacement = '#define mi_decl_hidden'
        # # Perform the replacement using regex (multiline mode)
        # content = re.sub(pattern, replacement, content, flags=re.MULTILINE)

        # # Write the modified content back to internal.h
        # with open(patch_head_file, 'w') as file:
        #     file.write(content)
        
    def generate(self):
        tc = CMakeToolchain(self)
        tc.cache_variables["MI_BUILD_STATIC"] = "ON"
        tc.cache_variables["MI_OVERRIDE"] = "OFF"
        tc.cache_variables["MI_LOCAL_DYNAMIC_TLS"] = "ON"
        
        if self.options.secure == True:
            tc.cache_variables["MI_SECURE"] = "ON"

        # if self.settings.os != "Windows":
        #     tc.cache_variables["CMAKE_C_FLAGS"] = "-ftls-model=global-dynamic"
        #     tc.cache_variables["CMAKE_CXX_FLAGS"] = "-ftls-model=global-dynamic"
        tc.generate()
    
    def build(self):
        cmake = CMake(self)
        cmake.configure(build_script_folder="./mimalloc")
        cmake.build()

    def package(self):
        cmake = CMake(self)
        cmake.install()
        # copy(self, "*", src=os.path.join(self.package_folder, "lib", "mimalloc-3.1"), dst=os.path.join(self.package_folder, "lib"), keep_path=True)

    def package_info(self):
        self.cpp_info.includedirs = [os.path.join('include', 'mimalloc-3.1')]
        self.cpp_info.libdirs = [os.path.join('lib', 'mimalloc-3.1')]
        # Static library only
        self.cpp_info.libs = ['mimalloc']
        #self.runenv_info.append_path(os.path.join(self.package_folder, "bin"))
        #self.runenv_info.append_path("PATH", os.path.join(self.package_folder, "bin"))
        #self.buildenv_info.append_path("PATH", os.path.join(self.package_folder, "bin"))
        return
