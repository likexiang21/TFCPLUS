plugins {
    id("net.neoforged.moddev") version "2.0.111"
}

val modId = "tfcagricultureplus"
val modVersion = "0.1.0"
val minecraftVersion = "1.21.1"
val neoForgeVersion = "21.1.233"

// 本机 mods 目录（支持工作区旧布局、分支根布局或显式 TFC_MODS_DIR）。
val modsDir = System.getenv("TFC_MODS_DIR")
    ?: listOf(
        rootProject.projectDir.resolve("../../mods"),
        rootProject.projectDir.resolve("../mods"),
        rootProject.projectDir.resolve("mods"),
    ).map { it.canonicalFile }.firstOrNull { it.isDirectory }?.path
    ?: error("[tfcagricultureplus] no mods directory found; set TFC_MODS_DIR or place mods/ next to the repo")

// ASCII-only log messages: the Gradle console here is GBK (see A's script note).
fun versionKey(name: String): List<Int> =
    Regex("\\d+").findAll(name).map { it.value.toIntOrNull() ?: 0 }.toList()

fun compareJarNames(left: String, right: String): Int {
    val a = versionKey(left)
    val b = versionKey(right)
    for (i in 0 until maxOf(a.size, b.size)) {
        val result = a.getOrElse(i) { 0 }.compareTo(b.getOrElse(i) { 0 })
        if (result != 0) return result
    }
    return left.compareTo(right)
}

fun latestJar(prefix: String): String {
    val jar = File(modsDir).listFiles { f -> f.name.startsWith(prefix) && f.name.endsWith(".jar") }
        ?.maxWithOrNull(Comparator { a, b -> compareJarNames(a.name, b.name) })
        ?: error("[tfcagricultureplus] no jar starting with '$prefix' found in: $modsDir")
    logger.lifecycle("[tfcagricultureplus] using dependency: ${jar.name}")
    return jar.absolutePath
}

val tfcJar       = latestJar("TerraFirmaCraft-NeoForge-")
val patchouliJar = latestJar("Patchouli-")
val firmalifeJar = latestJar("Firmalife-")
val afcJar       = latestJar("afc-")
val jeiJar       = latestJar("jei-")   // optional: compile-only, see mods.toml

val generateModMetadata = tasks.register<ProcessResources>("generateModMetadata") {
    val props = mapOf(
        "modId" to modId,
        "modVersion" to modVersion,
        "minecraftVersionRange" to "[$minecraftVersion]",
        "neoForgeVersionRange" to "[$neoForgeVersion,)",
        "tfcVersionRange" to "[4.2.8,)",
        "patchouliVersionRange" to "[1.21.1-92-NEOFORGE,)",
        "firmalifeVersionRange" to "[3.0.0,)",
        "aVersionRange" to "[0.1.0,)",
    )
    inputs.properties(props)
    expand(props)
    from("src/main/templates")
    into(layout.buildDirectory.dir("generated/sources/modMetadata"))
}

neoForge { version = neoForgeVersion }

base {
    archivesName.set("TFCAgriculturePlus-NeoForge-$minecraftVersion")
    group = "io.github.likexiang21.tfcplus.agriculture"
    version = modVersion
}

java { toolchain.languageVersion.set(JavaLanguageVersion.of(21)) }

// CJK comments must be read as UTF-8, otherwise javac (GBK default here) fails.
tasks.withType<JavaCompile>().configureEach {
    options.encoding = "UTF-8"
}

// ProcessResources filteringCharset defaults to the PLATFORM encoding (GBK here).
// The mods.toml template goes through expand(); any non-ASCII byte would be mangled
// and FML rejects the whole jar with "is not a valid mod file". Force UTF-8 + keep template ASCII.
tasks.withType<ProcessResources>().configureEach {
    filteringCharset = "UTF-8"
}

repositories {
    mavenCentral()
    maven {
        url = uri("https://bmclapi2.bangbang93.com/maven/")
        content { includeGroup("net.neoforged"); includeGroup("net.minecraftforge") }
    }
    exclusiveContent {
        forRepository { maven("https://maven.blamejared.com") }
        filter { includeGroup("vazkii.patchouli") }
    }
}

sourceSets {
    main { resources { srcDir(generateModMetadata) } }
}

neoForge {
    mods {
        create(modId) { sourceSet(sourceSets.main.get()) }
    }
    ideSyncTask(generateModMetadata)
}

dependencies {
    implementation(files(tfcJar))
    implementation(files(patchouliJar))
    implementation(files(firmalifeJar))
    implementation(files(afcJar))
    // No direct A Java imports: A is a runtime dependency declared in mods.toml, not a compile classpath jar.
    // JEI is OPTIONAL (TFC declares it the same way: type=optional, side=CLIENT)
    compileOnly(files(jeiJar))
}
