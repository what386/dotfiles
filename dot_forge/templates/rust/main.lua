-- .forge/templates/rust/main.lua

forge.on_init(function()
    local name = forge.project.name
    if not name:match("^[A-Za-z][A-Za-z0-9_%-]*$") then
        forge.abort("invalid project name '" .. name .. "' — must match ^[A-Za-z][A-Za-z0-9_-]*$")
    end
    forge.log.info("Scaffolding Rust project: " .. name)
end)

forge.on_error(function()
    forge.fs.remove(forge.project.dir)
end)

forge.on_complete(function()
    forge.log.success("Created " .. forge.project.name)
    forge.log.info("")
    forge.log.info("  cd " .. forge.project.name)
    forge.log.info("  cargo run")
end)

forge.args({
    git = {
        prompt  = "Initialize git repo?",
        type    = "boolean",
        default = true,
    },
})

forge.render_dir("")

forge.prog.rust.gen_lockfile()

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
