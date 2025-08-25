import org.gradle.api.file.Directory

// (Opsional) Pindahkan output build ke ../build/<subproject>
val buildRoot: Directory = rootProject.layout.projectDirectory.dir("../build")
rootProject.layout.buildDirectory.set(buildRoot.dir("root"))

subprojects {
    // setiap subproject build ke ../build/<nama-subproject>
    layout.buildDirectory.set(buildRoot.dir(name))

    // Paksa versi FFmpegKit ke 6.0-1
    configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "com.arthenica" && requested.name.startsWith("ffmpeg-kit-")) {
                useVersion("6.0-1") // ganti ke "6.0" kalau 6.0-1 masih 404
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
