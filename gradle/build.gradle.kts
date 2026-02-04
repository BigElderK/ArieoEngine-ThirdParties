import java.time.LocalDateTime

plugins {
    id("java-library")
    id("maven-publish")
}

repositories {
    google()
    mavenCentral()
}

// ========================================
// DEPENDENCIES CONFIGURATION
// ========================================

// Apply external dependencies configuration
apply(from = "dependencies.gradle.kts")

// Configuration for dependency resolution
configurations {
    create("androidDependencies") {
        description = "Android game development dependencies"
        isCanBeConsumed = false
        isCanBeResolved = true
    }
}

// Get dependencies from the external configuration
val androidGameDependencies: List<String> by extra
val androidTargetPlatforms: Set<String> by extra

// Android game development dependencies
dependencies {
    androidGameDependencies.forEach { dep ->
        "androidDependencies"(dep)
    }
}

// ========================================
// PLATFORM CONFIGURATION  
// ========================================

// Make targetPlatforms available to other build files
extra["targetPlatforms"] = androidTargetPlatforms

// ========================================
// TASK DEFINITIONS
// ========================================

// Include task definitions from separate files
apply(from = "gradle/tasks.gradle.kts")
apply(from = "gradle/cmake-config-generator.gradle.kts")