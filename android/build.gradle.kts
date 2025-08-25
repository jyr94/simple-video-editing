import org.gradle.api.file.Directory

// (Opsional) Pindahkan output build ke ../build/<subproject>
val buildRoot: Directory = rootProject.layout.projectDirectory.dir("../build")
rootProject.layout.buildDirectory.set(buildRoot.dir("root"))

subprojects {
    // setiap subproject build ke ../build/<nama-subproject>
    layout.buildDirectory.set(buildRoot.dir(name))

    // Ensure FFmpegKit matches the version bundled with ffmpeg_kit_flutter_new
    configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "com.arthenica" && requested.name.startsWith("ffmpeg-kit-")) {
                // Plugin ffmpeg_kit_flutter_new 3.2.0 currently ships with FFmpegKit 6.0
                // Update this pin when upgrading the plugin to avoid using outdated binaries
                useVersion("6.0")
            }
        }
    }

    // Repos — termasuk Flutter GCS agar artefak Flutter/engine ketemu
    repositories {
        google()
        mavenCentral()
        maven(url = "https://storage.googleapis.com/download.flutter.io")
    }
}

// Clean
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
