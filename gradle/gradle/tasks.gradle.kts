import java.time.LocalDateTime

// Task to copy dependencies to a specific location
tasks.register<Copy>("copyAndroidDependencies") {
    group = "dependencies"
    description = "Copy Android dependencies to output directory"
    
    from(configurations["androidDependencies"])
    into("${layout.buildDirectory.dir("dependencies/android").get()}")
    
    doLast {
        println("Android dependencies copied to: ${layout.buildDirectory.dir("dependencies/android").get()}")
    }
}

// Task to list all dependencies
tasks.register("listAndroidDependencies") {
    group = "dependencies"
    description = "List all Android dependencies with their versions"
    
    doLast {
        println("Android Game Development Dependencies:")
        println("=====================================")
        configurations["androidDependencies"].resolvedConfiguration.resolvedArtifacts.forEach { artifact ->
            println("${artifact.moduleVersion.id.group}:${artifact.moduleVersion.id.name}:${artifact.moduleVersion.id.version}")
        }
    }
}

// Task to generate dependency report
tasks.register("generateDependencyReport") {
    group = "dependencies"
    description = "Generate a detailed dependency report"
    
    doLast {
        val reportFile = layout.buildDirectory.file("reports/android-dependencies.txt").get().asFile
        reportFile.parentFile.mkdirs()
        
        reportFile.writeText("Android Game Development Dependencies Report\n")
        reportFile.appendText("Generated on: ${LocalDateTime.now()}\n")
        reportFile.appendText("===========================================\n\n")
        
        configurations["androidDependencies"].resolvedConfiguration.resolvedArtifacts.forEach { artifact ->
            reportFile.appendText("${artifact.moduleVersion.id.group}:${artifact.moduleVersion.id.name}:${artifact.moduleVersion.id.version}\n")
            reportFile.appendText("  File: ${artifact.file.name}\n")
            reportFile.appendText("  Size: ${artifact.file.length() / 1024} KB\n")
            reportFile.appendText("  Path: ${artifact.file.absolutePath}\n\n")
        }
        
        println("Dependency report generated: ${reportFile.absolutePath}")
    }
}

// Make the dependency report depend on resolution
tasks.named("generateDependencyReport") {
    dependsOn(configurations["androidDependencies"])
}

// Make copy task depend on resolution
tasks.named("copyAndroidDependencies") {
    dependsOn(configurations["androidDependencies"])
}