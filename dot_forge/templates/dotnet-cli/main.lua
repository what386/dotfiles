forge.on_init(function()
    local name = forge.project.name

    if not name:match("^[A-Za-z][A-Za-z0-9_%-]*$") then
        forge.abort(
            "invalid project name '" ..
            name ..
            "' — must match ^[A-Za-z][A-Za-z0-9_-]*$"
        )
    end

    forge.log.info("Scaffolding .NET project: " .. name)
end)

forge.on_error(function()
    forge.fs.remove(forge.project.dir)
end)

forge.on_complete(function()
    local name = forge.project.name

    forge.log.success("Created " .. name)
    forge.log.info("")
    forge.log.info("  cd " .. name)
    forge.log.info("  dotnet run --project src/" .. name)
end)

forge.args({
    git = {
        prompt  = "Initialize git repo?",
        type    = "boolean",
        default = true,
    },
})

local name = forge.project.name
local project_dir = "src/" .. name
local project_file = project_dir .. "/" .. name .. ".csproj"
local solution_file = name .. ".slnx"

forge.render_dir("")

forge.fs.mkdir(project_dir, { recursive = true })

forge.prog.dotnet.new("sln", {
    name   = name,
    format = "slnx",
})

forge.prog.dotnet.new("console", {
    name        = name,
    output      = project_dir,
    no_restore  = true,
})

forge.prog.dotnet.sln_add(solution_file, project_file)

forge.prog.dotnet.restore(solution_file, {
    use_lock_file = true,
})

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
