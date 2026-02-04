/**
 * Android Game Development Dependencies Configuration
 * 
 * This file contains the library dependencies and platform configuration
 * that will be processed by the Gradle build system.
 */

// ========================================
// ANDROID DEPENDENCIES
// ========================================
// These are the Android game development libraries that will be downloaded
// and processed to generate CMake configuration files.

val androidGameDependencies = listOf(
    "androidx.appcompat:appcompat:1.4.1",
    "androidx.games:games-frame-pacing:2.1.3",
    "androidx.games:games-performance-tuner:2.0.0", 
    "androidx.games:games-activity:4.0.0",
    "androidx.games:games-controller:2.0.2"
)

// ========================================
// TARGET PLATFORMS
// ========================================
// Specify which Android architectures to generate CMake configs for.
// Available options: "arm64-v8a", "armeabi-v7a", "x86_64", "x86"

val androidTargetPlatforms = setOf(
    "arm64-v8a"  // 64-bit ARM (most common for modern Android devices)
    // "armeabi-v7a",  // 32-bit ARM
    // "x86_64",       // 64-bit x86 (emulators)
    // "x86"           // 32-bit x86 (older emulators)
)

// Make variables available to the main build script
extra["androidGameDependencies"] = androidGameDependencies
extra["androidTargetPlatforms"] = androidTargetPlatforms

// ========================================
// PLATFORM MAPPING
// ========================================
// Internal mapping from ABI names to CMake platform identifiers
// (Do not modify unless you know what you're doing)

val androidArchitectureMapping = mapOf(
    "arm64-v8a" to "android.arm64-v8a",
    "armeabi-v7a" to "android.armeabi-v7a", 
    "x86_64" to "android.x86_64",
    "x86" to "android.x86"
)