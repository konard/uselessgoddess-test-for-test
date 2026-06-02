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
// The issue requires the app to support Android API 23, but several plugins
// inherit Flutter's defaults instead of declaring their real requirements:
//   * compileSdk: native_geofence pins 34, yet its transitive dependency
//     androidx.work:work-runtime:2.10.2 requires consumers to compile against
//     API 35+. We force every Android subproject to compile against API 36.
//   * minSdk: geolocator_android (and friends) declare flutter.minSdkVersion
//     (24) only because that is Flutter's default, not because of a real API-24
//     requirement. We lower library subprojects to API 23 so the merged
//     manifest stays consistent with the app's minSdk.
// Registered before the evaluationDependsOn block below so the callbacks are in
// place before any subproject is evaluated.
val issueMinSdk = 23

subprojects {
    val alignSdkVersions = {
        val androidExtension = project.extensions.findByName("android")
        if (androidExtension is com.android.build.gradle.BaseExtension) {
            val currentCompileSdk = androidExtension.compileSdkVersion
                ?.removePrefix("android-")
                ?.toIntOrNull() ?: 0
            if (currentCompileSdk < 36) {
                androidExtension.compileSdkVersion(36)
            }
            val currentMinSdk = androidExtension.defaultConfig.minSdk ?: 0
            if (currentMinSdk > issueMinSdk) {
                androidExtension.defaultConfig.minSdk = issueMinSdk
            }
        }
    }
    if (state.executed) alignSdkVersions() else afterEvaluate { alignSdkVersions() }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
