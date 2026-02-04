import logging
import shutil
from conan import ConanFile
from conan.tools.cmake import CMake, CMakeToolchain, CMakeDeps, cmake_layout
from conan.tools.scm import Git
from conan.tools.files import rmdir
from conan.tools.files import copy
import os

class StbConan(ConanFile):
    name = "stb"
    version = "master"
    #license = "<Put the package license here>"
    #author = "<Put your name here> <And your email here>"
    #url = "<Package recipe repository url here, for issues about the package>"
    #description = "<Description of Llvm here>"
    topics = ("vulkan")
    
    def source(self):
        self.run("git clone https://github.com/nothings/stb.git --branch %s" % (self.version))

    def generate(self):
        tc = CMakeToolchain(self)
        tc.generate()

    def build(self):
        return
        
    def package(self):
        src_include_folder = os.path.join("stb")
        
        copy(self, "*", src=src_include_folder, dst=os.path.join(self.package_folder))
        return

    def package_info(self): 
        self.cpp_info.includedirs = ['.']
        return