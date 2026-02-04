from conan import ConanFile
from conan.tools.files import get, copy, download
from conan.tools.cmake import cmake_layout
from conan.tools.cmake import CMakeToolchain
import os
import shutil


class WasmtimeConan(ConanFile):
    name = "wasmtime"
    version = "40.0.1"
    description = "A fast and secure runtime for WebAssembly"
    homepage = "https://wasmtime.dev/"
    url = "https://github.com/bytecodealliance/wasmtime"
    license = "Apache-2.0 WITH LLVM-exception"
    
    settings = "os", "arch", "build_type"
        
    options = {"shared": [True, False]}
    default_options = {"shared": False}

    def layout(self):
        cmake_layout(self, src_folder="./source", build_folder=os.path.join("./build", str(self.settings.os), str(self.settings.arch)))

    def source(self):
        # Clone wasmtime repository with specific version tag
        # self.run(f"wget https://github.com/bytecodealliance/wasmtime/releases/download/v{self.version}/wasmtime-v{self.version}-{self.settings.arch}-{self.settings.os}-c-api.tar.xz")

        git_url = "https://github.com/bytecodealliance/wasmtime.git"
        if self.version == "dev":
            self.run(f"git clone {git_url} --depth 1 wasmtime")
        else:
            self.run(f"git clone {git_url} --branch v{self.version} --depth 1 wasmtime")

    def build(self):
        """Download prebuild package directly from wasmtime releases"""
        # Different suffix based on OS
        if str(self.settings.os) == "Windows":
            suffix = "zip"
        else:
            suffix = "tar.xz"

        if str(self.settings.arch) == "x86":
            arch = "x86_64"
        elif str(self.settings.arch) == "armv8":
            arch = "aarch64"
        else:
            arch = str(self.settings.arch)
        
        # Download URL for the prebuilt package
        if self.version == "dev":
            download_url = f"https://github.com/bytecodealliance/wasmtime/releases/download/dev//wasmtime-dev-{arch}-{self.settings.os}-c-api.{suffix}"
        else:
            download_url = f"https://github.com/bytecodealliance/wasmtime/releases/download/v{self.version}/wasmtime-v{self.version}-{arch}-{self.settings.os}-c-api.{suffix}"
        
        # Download and extract the prebuilt package
        # Unpackaging is handled by get() with strip_root=True
        get(self, download_url, destination=self.build_folder, strip_root=True)
    
    def package(self):
        """Package the Wasmtime prebuilt binaries"""
        # Copy headers from the prebuilt package
        copy(self, "*", dst=self.package_folder, src=self.build_folder)
    
    # def get_target_triple(self):
    #     """Get the target triple for the current OS and architecture"""
    #     arch = str(self.settings.arch)
    #     os_name = str(self.settings.os)

    #     if os_name == "Linux":
    #         if arch == "x86_64":
    #             return "x86_64-unknown-linux-gnu"
    #         elif arch == "armv8":
    #             return "aarch64-unknown-linux-gnu"
    #     elif os_name == "Windows":
    #         if arch == "x86_64":
    #             return "x86_64-pc-windows-msvc"
    #     elif os_name == "Macos":
    #         if arch == "x86_64":
    #             return "x86_64-apple-darwin"
    #         elif arch == "armv8":
    #             return "aarch64-apple-darwin"
    #     elif os_name == "iOS":
    #         if arch == "armv8":
    #             return "aarch64-apple-ios"
    #     elif os_name == "Android":
    #         if arch == "armv8":
    #             return "aarch64-linux-android"
        
    #     raise Exception(f"Unsupported OS/Arch combination: {os_name}/{arch}")

    # def build(self):
    #     # run cargo build for wasmtime-c-api, and output to build folder
    #     target_triple = self.get_target_triple()
    #     os.environ["CARGO_BUILD_TARGET"] = target_triple
    #     os.environ["CARGO_TARGET_DIR"] = self.build_folder
    #     build_flag = "--release" if self.settings.build_type == "Release" else ""

    #     self.run(f"rustup target add {target_triple}")
    #     self.run(f"cargo build --manifest-path {self.source_folder}/wasmtime/Cargo.toml {build_flag} -p wasmtime-c-api --target {target_triple} --target-dir {self.build_folder}")
    
    # def package(self):
    #     """Package the Wasmtime prebuilt binaries"""
    #     # Copy headers from the prebuilt package
    #     target_triple = self.get_target_triple()
    #     copy(self, "*", dst=os.path.join(self.package_folder, "include"), src=os.path.join(self.source_folder, "wasmtime", "crates", "c-api", "include"))
    #     copy(self, "*", dst=os.path.join(self.package_folder, "lib"), src=os.path.join(self.build_folder, target_triple, str(self.settings.build_type)), excludes="*/*")
    
    def package_info(self):
        """Set package information for consumers"""
        self.cpp_info.includedirs = ["include"]
        self.cpp_info.libdirs = ['lib']
        
        if str(self.settings.os) == "Windows":
            self.cpp_info.libs = ["wasmtime.lib"]
            self.cpp_info.system_libs.append("ws2_32")
            self.cpp_info.system_libs.append("ntdll")
            self.cpp_info.system_libs.append("userenv")
            self.cpp_info.system_libs.append("bcrypt")
        else:
            self.cpp_info.libs = ["wasmtime"]

        self.cpp_info.defines = ["LIBWASM_STATIC"]
        
        