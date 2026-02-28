allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

fun org.gradle.api.Project.ensureLegacyTelephonyNamespace() {
    if (name != "telephony") return
    val androidExt = extensions.findByName("android") ?: return
    try {
        val getNamespace = androidExt.javaClass.methods.firstOrNull { it.name == "getNamespace" }
        val currentNamespace = getNamespace?.invoke(androidExt) as? String
        if (currentNamespace.isNullOrBlank()) {
            val setNamespace = androidExt.javaClass.methods.firstOrNull {
                it.name == "setNamespace" && it.parameterTypes.size == 1
            }
            setNamespace?.invoke(androidExt, "com.shounakmulay.telephony")
        }
    } catch (_: Exception) {
        // Ignore; this is a compatibility shim for older plugins.
    }
}

subprojects {
    // AGP 8+ requires a namespace; telephony 0.2.0 still ships without one.
    ensureLegacyTelephonyNamespace()
    plugins.whenPluginAdded {
        ensureLegacyTelephonyNamespace()
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
