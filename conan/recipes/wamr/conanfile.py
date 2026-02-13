from conan import ConanFile
from conan.tools.cmake import CMake, CMakeToolchain, CMakeDeps, cmake_layout
from conan.tools.scm import Git
from conan.tools.files import rmdir, copy
import os

class WamrConan(ConanFile):
    name = "wamr"
    version = "2.4.4"
    description = "WebAssembly Micro Runtime (WAMR)"
    homepage = "https://github.com/bytecodealliance/wasm-micro-runtime"
    url = "https://github.com/bytecodealliance/wasm-micro-runtime"
    license = "Apache-2.0 WITH LLVM-exception"
    
    settings = "os", "arch", "build_type", "compiler"
    
    exports_sources = "source/*"
    
    options = {
        "shared": [True, False],
        "fPIC": [True, False],
        "interp": [True, False],
        "fast_interp": [True, False],
        "aot": [True, False],
        "jit": [True, False],
        "libc_builtin": [True, False],
        "libc_wasi": [True, False],
        "multi_module": [True, False],
        "mini_loader": [True, False],
    }
    
    default_options = {
        "shared": False,
        "fPIC": True,
        "interp": True,
        "fast_interp": True,
        "aot": True,
        "jit": False,
        "libc_builtin": True,
        "libc_wasi": True,
        "multi_module": True,
        "mini_loader": False,
    }

    def config_options(self):
        if self.settings.os == "Windows":
            del self.options.fPIC

    def layout(self):
        cmake_layout(self, src_folder="./source", build_folder=os.path.join("./build", str(self.settings.os), str(self.settings.arch)))

    def source(self):
        git_url = "https://github.com/bytecodealliance/wasm-micro-runtime.git"
        if self.version == "dev":
            self.run(f"git clone {git_url} --depth 1 wamr")
        else:
            self.run(f"git clone {git_url} --branch WAMR-{self.version} --depth 1 wamr")

    def generate(self):
        tc = CMakeToolchain(self)
        
        # Enable/disable execution modes
        tc.cache_variables["WAMR_BUILD_INTERP"] = "1" if self.options.interp else "0"
        tc.cache_variables["WAMR_BUILD_FAST_INTERP"] = "1" if self.options.fast_interp else "0"
        tc.cache_variables["WAMR_BUILD_AOT"] = "1" if self.options.aot else "0"
        tc.cache_variables["WAMR_BUILD_JIT"] = "1" if self.options.jit else "0"
        
        # Library type
        tc.cache_variables["WAMR_BUILD_STATIC"] = "0" if self.options.shared else "1"
        
        # Libc support
        tc.cache_variables["WAMR_BUILD_LIBC_BUILTIN"] = "1" if self.options.libc_builtin else "0"
        tc.cache_variables["WAMR_BUILD_LIBC_WASI"] = "1" if self.options.libc_wasi else "0"
        
        # Multi-module support
        tc.cache_variables["WAMR_BUILD_MULTI_MODULE"] = "1" if self.options.multi_module else "0"
        tc.cache_variables["WAMR_BUILD_MINI_LOADER"] = "1" if self.options.mini_loader else "0"
        
        # Platform features
        tc.cache_variables["WAMR_BUILD_PLATFORM"] = self._get_platform()
        tc.cache_variables["WAMR_BUILD_TARGET"] = self._get_target()
        
        # Additional settings for better compatibility
        tc.cache_variables["WAMR_BUILD_BULK_MEMORY"] = "1"
        tc.cache_variables["WAMR_BUILD_SHARED_MEMORY"] = "1"
        tc.cache_variables["WAMR_BUILD_THREAD_MGR"] = "1"
        tc.cache_variables["WAMR_BUILD_LIB_PTHREAD"] = "1"
        tc.cache_variables["WAMR_BUILD_SIMD"] = "1"
        
        tc.generate()

    def _get_platform(self):
        """Get WAMR platform string based on Conan settings"""
        os_map = {
            "Linux": "linux",
            "Macos": "darwin",
            "Windows": "windows",
            "Android": "android",
            "iOS": "darwin",
        }
        return os_map.get(str(self.settings.os), "linux")

    def _get_target(self):
        """Get WAMR target architecture based on Conan settings"""
        arch_map = {
            "x86": "X86_32",
            "x86_64": "X86_64",
            "armv7": "ARM",
            "armv8": "AARCH64",
            "armv7hf": "ARM",
        }
        return arch_map.get(str(self.settings.arch), "X86_64")

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    def package(self):
        cmake = CMake(self)
        cmake.install()
        
        # Copy headers manually if not installed by CMake
        src_include = os.path.join(self.source_folder, "wamr", "core", "iwasm", "include")
        if os.path.exists(src_include):
            copy(self, "*.h", src=src_include, dst=os.path.join(self.package_folder, "include"), keep_path=True)

    def package_info(self):
        self.cpp_info.includedirs = ['include']
        self.cpp_info.libdirs = ['lib']
        
        # Determine platform system libraries
        if self.settings.os == "Linux":
            system_libs = ["pthread", "m", "dl"]
        elif self.settings.os == "Macos":
            system_libs = ["pthread", "m"]
        elif self.settings.os == "Windows":
            system_libs = ["ws2_32"]
        else:
            system_libs = []
        
        # Release variant: fast interpreter, optimized
        self.cpp_info.components["iwasm"].libs = ["iwasm"]
        self.cpp_info.components["iwasm"].includedirs = ["include"]
        self.cpp_info.components["iwasm"].system_libs = system_libs
        
        # Debug variant: classic interpreter, source debugging, call stack dump
        self.cpp_info.components["iwasm_d"].libs = ["iwasm_d"]
        self.cpp_info.components["iwasm_d"].includedirs = ["include"]
        self.cpp_info.components["iwasm_d"].system_libs = system_libs
