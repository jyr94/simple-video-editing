// android/build.gradle.kts (root project)

import org.gradle.api.file.Directory

// Tentukan root build folder sekali (TIDAK dari buildDirectory)
val buildRoot: Directory = rootProject.layout.projectDirectory.dir("../build")

// Root project build (opsional)
rootProject.layout.buildDirectory.set(buildRoot.dir("root"))

// Semua subproject build ke ../build/<nama-subproject>
subprojects {
    layout.buildDirectory.set(buildRoot.dir(name))
}

subprojects {
    repositories {
        google()
        mavenCentral()
        maven(url = "https://storage.googleapis.com/download.flutter.io")
    }
}
// Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
