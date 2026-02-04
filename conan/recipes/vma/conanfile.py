import logging
import shutil
from conan import ConanFile
from conan.tools.cmake import CMake, CMakeToolchain, CMakeDeps, cmake_layout
from conan.tools.scm import Git
from conan.tools.files import rmdir
from conan.tools.files import copy
import os

class VmaConan(ConanFile):
    name = "vma"
    version = "3.3.0"
    #license = "<Put the package license here>"
    #author = "<Put your name here> <And your email here>"
    #url = "<Package recipe repository url here, for issues about the package>"
    #description = "<Description of Llvm here>"
    topics = ("vulkan")
    
    def source(self):
        self.run("git clone https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator.git --branch v%s" % (self.version))

    def generate(self):
        tc = CMakeToolchain(self)
        tc.generate()

    def build(self):
        # cmake = CMake(self)
        # cmake.configure(build_script_folder="./VulkanMemoryAllocator")
        # cmake.build()
        return
        
    def package(self):
        src_include_folder = os.path.join("VulkanMemoryAllocator", "include")
        
        copy(self, "*.h", src=src_include_folder, dst=os.path.join(self.package_folder, "include"))
        copy(self, "*.hpp", src=src_include_folder, dst=os.path.join(self.package_folder, "include"))
        return

    def package_info(self): 
        self.cpp_info.includedirs = ['include']
        return