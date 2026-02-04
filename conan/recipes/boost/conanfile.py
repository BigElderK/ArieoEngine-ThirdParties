import logging
from conan import ConanFile
from conan.tools.cmake import CMake, CMakeToolchain, CMakeDeps, cmake_layout
from conan.tools.scm import Git
from conan.tools.files import rmdir
import os

class BoostConan(ConanFile):
    name = "boost"
    version = "1.87.0"
    topics = ("cmake", "build", "installer")
    settings = "os", "compiler", "build_type", "arch"

    package_type = "library"
    
    options = {"shared": [True, False], "fPIC": [True, False]}
    default_options = {"shared": False, "fPIC": True}

    #requires = {"openssl/3.4.1"}
    # default_user = "bigelderk"
    # default_channel = "default"

    def layout(self):
        cmake_layout(self, src_folder="./source", build_folder=os.path.join("./build", str(self.settings.os), str(self.settings.arch)))

    def source(self):
        self.run("git clone https://github.com/boostorg/boost.git --recurse-submodules --branch boost-%s --depth=1" % (self.version)) 
        
    def generate(self):
        tc = CMakeToolchain(self)
        tc.cache_variables["CMAKE_USE_OPENSSL"] = False
        #tc.cache_variables["BUILD_TESTING"] = True

        tc.cache_variables["BOOST_EXCLUDE_LIBRARIES"] = "process"

        if self.settings.os == "Windows":
            tc.cache_variables["CMAKE_CXX_FLAGS"] = "-D_WIN32_WINNT=0x0601 /EHsc /bigobj"

        if self.settings.os == "Android":
            tc.cache_variables["CMAKE_CXX_FLAGS"] = "-DDNO_WORDEXP -Wno-format-security -Wno-nonnull"
            tc.cache_variables["CMAKE_C_FLAGS"] = "-DDNO_WORDEXP -Wno-format-security -Wno-nonnull"


        tc.generate()
    
    def build(self):
        cmake = CMake(self)
        cmake.configure(build_script_folder="./boost")
        cmake.build()

    def package(self):
        cmake = CMake(self)
        cmake.install()

    def package_info(self):
        self.cpp_info.libdirs = ['lib']
        self.cpp_info.includedirs = ['include']

        #self.runenv_info.append_path(os.path.join(self.package_folder, "bin"))
        #self.runenv_info.append_path("PATH", os.path.join(self.package_folder, "bin"))
        #self.buildenv_info.append_path("PATH", os.path.join(self.package_folder, "bin"))
        return
