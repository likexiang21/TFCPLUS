plugins {
    id("net.neoforged.moddev") version "2.0.111"
}

val modId = "tfcfarmingplus"
val modVersion = "0.1.0"
val minecraftVersion = "1.21.1"
val neoForgeVersion = "21.1.233"

// 本机 mods 目录（离线依赖方案：直接引用发行 jar，类名为 mojmap 可直接编译）。
// 从项目位置解析，避免迁移电脑后仍指向旧工作区。
val modsDir = rootProject.projectDir.resolve("../../mods").canonicalPath

// 🆕 2026-09-28 整理：改为「自动取最新版」
//   ⚠️ 旧版硬编码 `TerraFirmaCraft-...-4.2.10.jar`，而 mods 目录里早已是 4.2.11
//      ⇒ `files()` 指向不存在的文件不报错，但**编译期会因找不到 `net.dries007.tfc.*` 而失败**（已实测）。
//   规则：取以指定前缀开头的 jar 中**文件名最大**的那个（版本号字典序 = 语义序）。
fun latestJar(prefix: String): String {
    val jar = File(modsDir).listFiles { f -> f.name.startsWith(prefix) && f.name.endsWith(".jar") }
        ?.maxByOrNull { it.name }
        ?: error("[tfcfarmingplus] no jar starting with '$prefix' found in: $modsDir")
    // NOTE: keep this message ASCII-only — the Gradle console here is GBK, CJK comes out garbled.
    logger.lifecycle("[tfcfarmingplus] using dependency: ${jar.name}")
    return jar.absolutePath
}
val tfcJar = latestJar("TerraFirmaCraft-NeoForge-")
val patchouliJar = latestJar("Patchouli-")

val generateModMetadata = tasks.register<ProcessResources>("generateModMetadata") {
    val props = mapOf(
        "modId" to modId,
        "modVersion" to modVersion,
        "minecraftVersionRange" to "[$minecraftVersion]",
        "neoForgeVersionRange" to "[$neoForgeVersion,)",
        "tfcVersionRange" to "[4.2.8,)",
        "patchouliVersionRange" to "[1.21.1-92-NEOFORGE,)",
    )
    inputs.properties(props)
    expand(props)
    from("src/main/templates")
    into(layout.buildDirectory.dir("generated/sources/modMetadata"))
}

neoForge { version = neoForgeVersion }

base {
    archivesName.set("TFCFarmingPlus-NeoForge-$minecraftVersion")
    group = "io.github.likexiang21.tfcplus.farming"
    version = modVersion
}

java { toolchain.languageVersion.set(JavaLanguageVersion.of(21)) }

// 中文注释必须显式 UTF-8，否则 javac 按 GBK 读取会报不可映射字符
tasks.withType<JavaCompile>().configureEach {
    options.encoding = "UTF-8"
}

// ⚠️ 关键：ProcessResources 的 filteringCharset 默认是【平台编码】（本机为 GBK）。
// neoforge.mods.toml 模板要经过 expand(replaceProperties) 处理，一旦模板里有非 ASCII 字符，
// 就会被按 GBK 解码→再按 UTF-8 写出，产物出现非法字节，FML 直接判定
// "is not a valid mod file / MalformedInputException" 并拒绝加载整个 jar（已实测踩坑）。
// 这里显式设为 UTF-8 作为防御；同时模板本身也保持纯 ASCII。
tasks.withType<ProcessResources>().configureEach {
    filteringCharset = "UTF-8"
}

// Retain the historical source archive without shipping a nested texture backup.
tasks.named<ProcessResources>("processResources") {
    exclude("assets/tfcfarmingplus/textures.zip")
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
}
