import logging
import shutil
from conan import ConanFile
from conan.tools.cmake import CMake, CMakeToolchain, CMakeDeps, cmake_layout
from conan.tools.scm import Git
from conan.tools.files import rmdir
import os

class TinyObjLoaderConan(ConanFile):
    name = "tinyobjloader"
    version = "v2.0.0rc13"
    #license = "<Put the package license here>"
    #author = "<Put your name here> <And your email here>"
    #url = "<Package recipe repository url here, for issues about the package>"
    #description = "<Description of Llvm here>"
    topics = ("string")
    settings = "os", "compiler", "build_type", "arch"
    
    options = {"shared": [True, False], "fPIC": [True, False]}
    default_options = {"shared": False, "fPIC": True}

    generators = "CMakeDeps"
    
    #def requirements(self):
        #if self.settings.os in ["Linux", "FreeBSD"]:
            #self.requires("xorg/system")
            #self.requires("wayland/1.22.0")
            #self.requires("xkbcommon/1.6.0")
        
    def layout(self):
        cmake_layout(self, src_folder="./source", build_folder=os.path.join("./build", str(self.settings.os), str(self.settings.arch)))

    def source(self):
        self.run("git clone https://github.com/tinyobjloader/tinyobjloader.git --branch %s" % (self.version))

    def generate(self):
        tc = CMakeToolchain(self)
        tc.generate()

    def build(self):
        cmake = CMake(self)
        cmake.configure(build_script_folder="./tinyobjloader")
        cmake.build()
        return
        
    def package(self):
        cmake = CMake(self)
        cmake.install()
        return

    def package_info(self):
        self.cpp_info.includedirs = ['include']
        self.cpp_info.libdirs = ['lib']
        self.cpp_info.libs = ['tinyobjloader']
      
        return