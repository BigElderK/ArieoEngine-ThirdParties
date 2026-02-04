// Task to generate CMake config files for Android dependencies
tasks.register("generateCMakeConfigs") {
    group = "cmake"
    description = "Generate CMake config files for specified Android dependencies and platforms"
    
    dependsOn(configurations["androidDependencies"])
    
    doLast {
        // Use target platforms from build.gradle.kts
        val targetPlatformsFromMain = (project.extra["targetPlatforms"] as? Set<*>)?.filterIsInstance<String>()?.toSet()
            ?: setOf("arm64-v8a") // fallback if not found
        
        val cmakeConfigDir = layout.buildDirectory.dir("cmake-configs").get().asFile
        val extractedDir = layout.buildDirectory.dir("extracted-aars").get().asFile
        val libsDir = layout.buildDirectory.dir("libs").get().asFile
        cmakeConfigDir.mkdirs()
        extractedDir.mkdirs()
        libsDir.mkdirs()
        
        // Only process specified platforms
        val androidArchs = mapOf(
            "arm64-v8a" to "android/arm64-v8a",
            "armeabi-v7a" to "android/armeabi-v7a",
            "x86_64" to "android/x86_64",
            "x86" to "android/x86"
        ).filterKeys { it in targetPlatformsFromMain }
        
        println("Processing dependencies for platforms: ${targetPlatformsFromMain.joinToString(", ")}")
        
        // Process all explicitly declared dependencies (no hardcoded list)
        // Get only direct dependencies, not transitive ones
        val directDependencies = configurations["androidDependencies"].allDependencies
        val directCoordinates = directDependencies.map { "${it.group}:${it.name}:${it.version}" }.toSet()
        
        val specifiedDependencies = configurations["androidDependencies"].resolvedConfiguration.resolvedArtifacts
            .filter { artifact ->
                val coords = "${artifact.moduleVersion.id.group}:${artifact.moduleVersion.id.name}:${artifact.moduleVersion.id.version}"
                val isDirect = directCoordinates.contains(coords)
                if (!isDirect) {
                    println("Skipping transitive dependency: ${coords}")
                }
                isDirect
            }
        
        println("Processing ${specifiedDependencies.size} explicitly listed dependencies:")
        specifiedDependencies.forEach { artifact ->
            println("  - ${artifact.moduleVersion.id.group}:${artifact.moduleVersion.id.name}:${artifact.moduleVersion.id.version}")
        }
        
        specifiedDependencies.forEach { artifact ->
            val moduleName = artifact.moduleVersion.id.name
            val groupId = artifact.moduleVersion.id.group
            val version = artifact.moduleVersion.id.version
            val artifactFile = artifact.file
            
            println("Processing: ${groupId}:${moduleName}:${version}")
            
            // Copy the original artifact to libs directory
            val libFile = File(libsDir, artifactFile.name)
            artifactFile.copyTo(libFile, overwrite = true)
            println("  Copied to libs: ${libFile.absolutePath}")
            
            // Extract AAR if it's an AAR file
            val moduleExtractDir = File(extractedDir, "${groupId}-${moduleName}-${version}")
            
            if (artifactFile.name.endsWith(".aar")) {
                moduleExtractDir.mkdirs()
                
                // Extract AAR file
                copy {
                    from(zipTree(artifactFile))
                    into(moduleExtractDir)
                }
                
                println("  Extracted AAR to: ${moduleExtractDir.absolutePath}")
            }
            
            // Generate CMake configs only for specified architectures
            androidArchs.forEach { (abiName, platformName) ->
                val platformConfigDir = File(cmakeConfigDir, "${platformName}/cmake")
                val platformLibsDir = File(libsDir, platformName)
                platformConfigDir.mkdirs()
                platformLibsDir.mkdirs()
                
                var libPath = ""
                var includePath = ""
                val availableModules = mutableMapOf<String, Pair<String, String>>() // moduleName -> (libPath, includePath)
                
                if (artifactFile.name.endsWith(".aar")) {
                    // Look for native libraries and headers for this architecture
                    val prefabDir = File(moduleExtractDir, "prefab")
                    val jniDir = File(moduleExtractDir, "jni")
                    
                    if (prefabDir.exists()) {
                        // Handle Prefab structure - collect all modules first
                        val modulesDir = File(prefabDir, "modules")
                        if (modulesDir.exists()) {
                            modulesDir.listFiles()?.forEach { moduleDir ->
                                if (moduleDir.isDirectory) {
                                    val prefabModuleName = moduleDir.name
                                    val libsSourceDir = File(moduleDir, "libs")
                                    val includeDir = File(moduleDir, "include")
                                    
                                    var moduleLibPath = ""
                                    var moduleIncludePath = ""
                                    
                                    if (libsSourceDir.exists()) {
                                        // Look for architecture-specific libs
                                        val archLibDir = File(libsSourceDir, "android.${abiName}")
                                        if (archLibDir.exists()) {
                                            archLibDir.listFiles()?.forEach { file ->
                                                if (file.name.endsWith(".a") || file.name.endsWith(".so")) {
                                                    // Use the original extracted path directly
                                                    moduleLibPath = file.absolutePath.replace("\\", "/")
                                                    println("    Found native lib [${abiName}]: ${file.absolutePath}")
                                                }
                                            }
                                        }
                                    }
                                    
                                    if (includeDir.exists()) {
                                        // Use the original extracted include path directly
                                        moduleIncludePath = includeDir.absolutePath.replace("\\", "/")
                                        println("    Found headers [${abiName}]: ${includeDir.absolutePath}")
                                    }
                                    
                                    if (moduleLibPath.isNotEmpty() || moduleIncludePath.isNotEmpty()) {
                                        availableModules[prefabModuleName] = Pair(moduleLibPath, moduleIncludePath)
                                    }
                                }
                            }
                        }
                    } else if (jniDir.exists()) {
                        // Handle traditional JNI structure
                        val archJniDir = File(jniDir, abiName)
                        if (archJniDir.exists()) {
                            archJniDir.listFiles()?.forEach { file ->
                                if (file.name.endsWith(".a") || file.name.endsWith(".so")) {
                                    val targetLibFile = File(platformLibsDir, file.name)
                                    file.copyTo(targetLibFile, overwrite = true)
                                    libPath = targetLibFile.absolutePath.replace("\\", "/")
                                    println("    Copied JNI lib [${abiName}]: ${targetLibFile.absolutePath}")
                                }
                            }
                        }
                        
                        // Look for headers in common locations
                        val headersDir = File(moduleExtractDir, "headers")
                        val includeDir = File(moduleExtractDir, "include")
                        if (headersDir.exists()) {
                            val targetIncludeDir = File(platformLibsDir, "include/${moduleName}")
                            targetIncludeDir.mkdirs()
                            copy {
                                from(headersDir)
                                into(targetIncludeDir)
                            }
                            // Point to the base include directory, not the subdirectory
                            includePath = File(platformLibsDir, "include").absolutePath.replace("\\", "/")
                        } else if (includeDir.exists()) {
                            val targetIncludeDir = File(platformLibsDir, "include/${moduleName}")
                            targetIncludeDir.mkdirs()
                            copy {
                                from(includeDir)
                                into(targetIncludeDir)
                            }
                            // Point to the base include directory, not the subdirectory
                            includePath = File(platformLibsDir, "include").absolutePath.replace("\\", "/")
                        }
                    }
                } else {
                    // For JAR files, copy to platform libs directory
                    val targetJarFile = File(platformLibsDir, artifactFile.name)
                    artifactFile.copyTo(targetJarFile, overwrite = true)
                    libPath = targetJarFile.absolutePath.replace("\\", "/")
                    println("    Copied JAR [${abiName}]: ${targetJarFile.absolutePath}")
                }
                
                // Create CMake config file for this platform
                // Helper functions for naming conventions
                fun getConfigFileName(groupId: String, moduleName: String, availableModules: Map<String, Pair<String, String>>, moduleExtractDir: File): String {
                    // First, try to read the name from prefab.json
                    val prefabJsonFile = File(moduleExtractDir, "prefab/prefab.json")
                    if (prefabJsonFile.exists()) {
                        try {
                            val jsonText = prefabJsonFile.readText()
                            // Simple JSON parsing to extract the "name" field
                            val namePattern = """"name"\s*:\s*"([^"]+)"""".toRegex()
                            val matchResult = namePattern.find(jsonText)
                            if (matchResult != null) {
                                return "${matchResult.groupValues[1]}Config.cmake"
                            }
                        } catch (e: Exception) {
                            println("    Warning: Could not parse prefab.json: ${e.message}")
                        }
                    }
                    
                    // Fallback: use first discovered prefab module name
                    if (availableModules.isNotEmpty()) {
                        return "${availableModules.keys.first()}Config.cmake"
                    } else {
                        // Final fallback to the original module name
                        return "${moduleName}Config.cmake"
                    }
                }
                
                fun getCMakeNamespace(groupId: String, moduleName: String, availableModules: Map<String, Pair<String, String>>, moduleExtractDir: File): String {
                    // First, try to read the name from prefab.json
                    val prefabJsonFile = File(moduleExtractDir, "prefab/prefab.json")
                    if (prefabJsonFile.exists()) {
                        try {
                            val jsonText = prefabJsonFile.readText()
                            // Simple JSON parsing to extract the "name" field
                            val namePattern = """"name"\s*:\s*"([^"]+)"""".toRegex()
                            val matchResult = namePattern.find(jsonText)
                            if (matchResult != null) {
                                return matchResult.groupValues[1]
                            }
                        } catch (e: Exception) {
                            println("    Warning: Could not parse prefab.json: ${e.message}")
                        }
                    }
                    
                    // Fallback: use first discovered prefab module name
                    if (availableModules.isNotEmpty()) {
                        return availableModules.keys.first()
                    } else {
                        // Final fallback to the original module name
                        return moduleName
                    }
                }
                
                val configFileName = getConfigFileName(groupId, moduleName, availableModules, moduleExtractDir)
                val configFile = File(platformConfigDir, configFileName)
                
                val cmakeContent = StringBuilder()
                cmakeContent.append("""
# Generated CMake config for ${moduleName}
# Group: ${groupId}
# Version: ${version}
# Platform: ${platformName} (${abiName})
# Original file: ${artifactFile.name}

""".trimIndent())

                // If it's an AAR with prefab modules, create all available targets
                if (artifactFile.name.endsWith(".aar") && availableModules.isNotEmpty()) {
                    availableModules.forEach { (subModuleName, paths) ->
                        val (subLibPath, subIncludePath) = paths
                        
                        if (subLibPath.isNotEmpty()) {
                            val cmakeNamespace = getCMakeNamespace(groupId, moduleName, availableModules, moduleExtractDir)
                            cmakeContent.append("""
if(NOT TARGET ${cmakeNamespace}::${subModuleName})
    add_library(${cmakeNamespace}::${subModuleName} STATIC IMPORTED)
    set_target_properties(${cmakeNamespace}::${subModuleName} PROPERTIES
        IMPORTED_LOCATION "${subLibPath}"
""")
                            if (subIncludePath.isNotEmpty()) {
                                cmakeContent.append("        INTERFACE_INCLUDE_DIRECTORIES \"${subIncludePath}\"\n")
                            }
                            cmakeContent.append("""        INTERFACE_LINK_LIBRARIES ""
    )
endif()

""")
                        } else if (subIncludePath.isNotEmpty()) {
                            // Header-only module
                            val cmakeNamespace = getCMakeNamespace(groupId, moduleName, availableModules, moduleExtractDir)
                            cmakeContent.append("""
if(NOT TARGET ${cmakeNamespace}::${subModuleName})
    add_library(${cmakeNamespace}::${subModuleName} INTERFACE)
    set_target_properties(${cmakeNamespace}::${subModuleName} PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${subIncludePath}"
    )
endif()

""")
                        }
                    }
                } else if (artifactFile.name.endsWith(".aar") && libPath.isNotEmpty()) {
                    // AAR with traditional JNI structure
                    val cmakeNamespace = getCMakeNamespace(groupId, moduleName, availableModules, moduleExtractDir)
                    cmakeContent.append("""
if(NOT TARGET ${cmakeNamespace}::${moduleName})
    add_library(${cmakeNamespace}::${moduleName} STATIC IMPORTED)
    set_target_properties(${cmakeNamespace}::${moduleName} PROPERTIES
        IMPORTED_LOCATION "${libPath}"
""")
                    if (includePath.isNotEmpty()) {
                        cmakeContent.append("        INTERFACE_INCLUDE_DIRECTORIES \"${includePath}\"\n")
                    }
                    cmakeContent.append("""        INTERFACE_LINK_LIBRARIES ""
    )
endif()

""")
                } else if (artifactFile.name.endsWith(".aar") && includePath.isNotEmpty()) {
                    // AAR with headers only
                    val cmakeNamespace = getCMakeNamespace(groupId, moduleName, availableModules, moduleExtractDir)
                    cmakeContent.append("""
if(NOT TARGET ${cmakeNamespace}::${moduleName})
    add_library(${cmakeNamespace}::${moduleName} INTERFACE)
    set_target_properties(${cmakeNamespace}::${moduleName} PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${includePath}"
    )
endif()

""")
                } else if (artifactFile.name.endsWith(".jar")) {
                    // For JAR files
                    val cmakeNamespace = getCMakeNamespace(groupId, moduleName, availableModules, moduleExtractDir)
                    cmakeContent.append("""
if(NOT TARGET ${cmakeNamespace}::${moduleName})
    add_library(${cmakeNamespace}::${moduleName} INTERFACE)
    set_target_properties(${cmakeNamespace}::${moduleName} PROPERTIES
        INTERFACE_JAR_FILE "${libPath}"
    )
endif()

""")
                } else {
                    // Fallback for empty AARs
                    val cmakeNamespace = getCMakeNamespace(groupId, moduleName, availableModules, moduleExtractDir)
                    cmakeContent.append("""
if(NOT TARGET ${cmakeNamespace}::${moduleName})
    add_library(${cmakeNamespace}::${moduleName} INTERFACE)
    # No properties set - empty dependency
endif()

""")
                }
                
                // Add convenience variables
                val cmakeNamespace = getCMakeNamespace(groupId, moduleName, availableModules, moduleExtractDir)
                cmakeContent.append("""
# Convenience variables
set(${moduleName.uppercase().replace("-", "_")}_FOUND TRUE)
set(${moduleName.uppercase().replace("-", "_")}_LIBRARIES ${cmakeNamespace}::${moduleName})
""")
                
                configFile.writeText(cmakeContent.toString())
                println("    Generated CMake config [${platformName}]: ${configFile.absolutePath}")
            }
        }
        
        // Generate master include files only for specified platforms
        androidArchs.forEach { (abiName, platformName) ->
            val platformConfigDir = File(cmakeConfigDir, "${platformName}/cmake")
            val masterFile = File(platformConfigDir, "AndroidGameDependencies.cmake")
            
            masterFile.writeText("""
# Master CMake file for specified Android Game dependencies
# Platform: ${platformName} (${abiName})
# Include this file in your CMakeLists.txt

# Set the path where config files are located
set(AndroidGameDeps_DIR "${platformConfigDir.absolutePath.replace("\\", "/")}")
set(AndroidGameDeps_LIBS_DIR "${libsDir.absolutePath.replace("\\", "/")}")
set(AndroidGameDeps_PLATFORM "${platformName}")
set(AndroidGameDeps_ABI "${abiName}")

# Include all the config files for specified dependencies
""".trimIndent())
            
            specifiedDependencies.forEach { artifact ->
                val moduleName = artifact.moduleVersion.id.name
                masterFile.appendText("include(\"\${AndroidGameDeps_DIR}/${moduleName}Config.cmake\")\n")
            }
            
            masterFile.appendText("""

# Function to link specified Android Game dependencies to a target
function(target_link_android_game_dependencies target_name)
""")
            
            specifiedDependencies.forEach { artifact ->
                val groupId = artifact.moduleVersion.id.group
                val moduleName = artifact.moduleVersion.id.name
                val artifactFile = artifact.file
                
                // For AARs with prefab, we'll try to link the most appropriate target
                if (artifactFile.name.endsWith(".aar")) {
                    val moduleExtractDir = File(extractedDir, "${groupId}-${moduleName}-${version}")
                    val prefabDir = File(moduleExtractDir, "prefab/modules")
                    
                    if (prefabDir.exists()) {
                        // For prefab AARs, try to find the best target to link
                        val availableTargets = mutableListOf<String>()
                        prefabDir.listFiles()?.forEach { moduleDir ->
                            if (moduleDir.isDirectory) {
                                availableTargets.add(moduleDir.name)
                            }
                        }
                        
                        // Prefer targets that match the module name or contain "static"
                        val preferredTarget = availableTargets.find { it.contains(moduleName.replace("-", "_")) } 
                            ?: availableTargets.find { it.contains("static") } 
                            ?: availableTargets.firstOrNull()
                        
                        if (preferredTarget != null) {
                            masterFile.appendText("    target_link_libraries(\${target_name} ${groupId}::${preferredTarget})\n")
                        }
                    } else {
                        // Traditional AAR
                        masterFile.appendText("    target_link_libraries(\${target_name} ${groupId}::${moduleName})\n")
                    }
                } else {
                    // JAR files
                    masterFile.appendText("    target_link_libraries(\${target_name} ${groupId}::${moduleName})\n")
                }
            }
            
            masterFile.appendText("endfunction()\n")
            
            println("Generated master file [${platformName}]: ${masterFile.absolutePath}")
        }
        
        println("\nGenerated files:")
        println("- Original artifacts: ${libsDir.absolutePath}")
        println("- Extracted AARs: ${extractedDir.absolutePath}")
        println("- CMake configs: ${cmakeConfigDir.absolutePath}")
        println("\nTo use in your CMakeLists.txt:")
        val firstPlatform = androidArchs.values.first()
        println("include(\"${cmakeConfigDir.absolutePath.replace("\\", "/")}/${firstPlatform}/cmake/AndroidGameDependencies.cmake\")")
        println("target_link_android_game_dependencies(your_target_name)")
        println("\nTo change target platforms, modify the 'targetPlatforms' variable in build.gradle.kts")
    }
}