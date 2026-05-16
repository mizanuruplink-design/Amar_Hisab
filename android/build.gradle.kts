plugins {
    // এখানে ভার্সন নম্বর (8.2.1) দেওয়ার দরকার নেই, কারণ ফ্লাটার নিজেই এটি ম্যানেজ করছে
    id("com.android.application") apply false
    id("org.jetbrains.kotlin.android") apply false

    // শুধু ফায়ারবেস প্লাগইনের ভার্সনটি উল্লেখ করে দিন
    id("com.google.gms.google-services") version "4.4.1" apply false
}

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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}