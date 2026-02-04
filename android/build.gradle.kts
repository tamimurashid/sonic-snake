allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// Removed evaluationDependsOn(":app") to avoid "project already evaluated" errors.

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    val project = this
    fun applyNamespaceWorkaround() {
        if (project.extensions.findByName("android") != null) {
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
            if (android.namespace == null) {
                val manifestFile = project.file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    val manifestContent = manifestFile.readText()
                    val packageMatch = Regex("package=\"([^\"]+)\"").find(manifestContent)
                    val packageName = packageMatch?.groupValues?.get(1)
                    if (packageName != null) {
                        android.namespace = packageName
                    }
                }
            }
        }
    }

    if (project.state.executed) {
        applyNamespaceWorkaround()
        applyJvmTargetWorkaround(project)
    } else {
        project.afterEvaluate {
            applyNamespaceWorkaround()
            applyJvmTargetWorkaround(project)
        }
    }
}

fun applyJvmTargetWorkaround(project: Project) {
    project.tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        kotlinOptions {
            jvmTarget = "11"
        }
    }
    project.extensions.findByType<com.android.build.gradle.BaseExtension>()?.apply {
        compileOptions {
            sourceCompatibility = JavaVersion.VERSION_11
            targetCompatibility = JavaVersion.VERSION_11
        }
    }
}
