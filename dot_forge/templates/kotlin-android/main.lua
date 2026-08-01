-- .forge/templates/kotlin-android/main.lua

local name = forge.project.name
local package_suffix = forge.str.snake(name)
local package_name = "com.example." .. package_suffix
local package_path = "com/example/" .. package_suffix

forge.on_init(function()
    if not name:match("^[A-Za-z][A-Za-z0-9_%-]*$") then
        forge.abort(
            "invalid project name '" ..
            name ..
            "' — must match ^[A-Za-z][A-Za-z0-9_-]*$"
        )
    end

    forge.log.info("Scaffolding Kotlin Android project: " .. name)
end)

forge.on_error(function()
    forge.fs.remove(forge.project.dir)
end)

forge.on_complete(function()
    forge.log.success("Created " .. name)
    forge.log.info("")
    forge.log.info("  cd " .. name)
    forge.log.info("  just run-debug")
end)

forge.args({
    git = {
        prompt  = "Initialize git repo?",
        type    = "boolean",
        default = true,
    },
})

-- Render directories explicitly so ignored Gradle/build output accidentally
-- present in the template checkout is never copied into a new project.
forge.render_dir(".github")
forge.render_dir("app/src/main/res")
forge.render_dir("fastlane")
forge.render_dir("scripts")

forge.render(".editorconfig")
forge.render(".envrc")
forge.render(".gitattributes")
forge.render(".gitignore")
forge.render(".tool-versions")
forge.render("CHANGELOG.md")
forge.render("Justfile.tpl")
forge.render("LICENSE")
forge.render("README.md.tpl")
forge.render("TODO.md")
forge.render("gradle.properties")
forge.render("gradle/libs.versions.toml")
forge.render("gradle/wrapper/gradle-wrapper.properties")
forge.render("gradlew")
forge.render("gradlew.bat")
forge.render("settings.gradle.kts.tpl")
forge.render("app/build.gradle.kts.tpl")
forge.render("app/proguard-rules.pro")
forge.render("app/src/main/AndroidManifest.xml.tpl")

forge.render_dir_to(
    "app/src/main/java/com/example/app",
    "app/src/main/java/" .. package_path
)

if forge.vars.git then
    local ok = forge.prog.git.init({ allow_fail = true })
    if ok then
        forge.prog.git.add("-A")
        forge.prog.git.commit("chore: initial scaffold via forge")
        forge.log.success("Git repo initialized")
    else
        forge.log.warn("git init failed — skipping")
    end
end
