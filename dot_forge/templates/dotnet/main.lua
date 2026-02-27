local function shell_quote(value)
  local text = tostring(value)
  return "'" .. text:gsub("'", "'\\''") .. "'"
end

local function to_pascal_case(text)
  local parts = {}
  for part in tostring(text):gmatch("[A-Za-z0-9]+") do
    local lower = part:lower()
    parts[#parts + 1] = lower:sub(1, 1):upper() .. lower:sub(2)
  end
  return table.concat(parts, "")
end

local function chmod_executable(forge, path)
  forge.exec.run("chmod +x " .. shell_quote(path))
end

local function parse_remotes(raw)
  local remotes = {}
  local seen = {}

  for remote in tostring(raw):gmatch("[^,%s]+") do
    if not seen[remote] then
      seen[remote] = true
      remotes[#remotes + 1] = remote
    end
  end

  return remotes
end

local function to_lash_string_array(values)
  local quoted = {}
  for _, value in ipairs(values) do
    quoted[#quoted + 1] = shell_quote(value)
  end
  return "[" .. table.concat(quoted, ", ") .. "]"
end

return {
  options = function(cli)
    cli:option("template", {
      type = "string",
      default = "console",
      help = "Template passed to `dotnet new <template>` for the primary project",
    })

    cli:option("sdk-version", {
      type = "string",
      default = "10.0.x",
      help = ".NET SDK channel used by CI workflows",
    })

    cli:option("remotes", {
      type = "string",
      default = "github,gitea",
      help = "Comma- or space-separated git remotes used in release scripts",
    })
  end,

  run = function(forge)
    local project_name = to_pascal_case(forge.args.name)
    local tests_project = project_name .. ".Tests"
    local primary_project = project_name

    forge.fs.mkdir_p("src")
    forge.fs.mkdir_p("tests")

    forge.exec.run("dotnet new sln -n " .. shell_quote(project_name))
    forge.exec.run(
      "dotnet new " .. shell_quote(forge.args.template) ..
      " -n " .. shell_quote(primary_project) ..
      " --no-restore -o " .. shell_quote("src/" .. primary_project)
    )
    forge.exec.run(
      "dotnet new xunit -n " .. shell_quote(tests_project) ..
      " --no-restore -o " .. shell_quote("tests/" .. tests_project)
    )

    forge.exec.run(
      "dotnet sln add " ..
      shell_quote("src/" .. primary_project .. "/" .. primary_project .. ".csproj") .. " " ..
      shell_quote("tests/" .. tests_project .. "/" .. tests_project .. ".csproj")
    )
    forge.exec.run(
      "dotnet add " ..
      shell_quote("tests/" .. tests_project .. "/" .. tests_project .. ".csproj") ..
      " reference " ..
      shell_quote("src/" .. primary_project .. "/" .. primary_project .. ".csproj")
    )

    local remotes = parse_remotes(forge.args.remotes)

    local vars = {
      project_name = project_name,
      project_slug = forge.args.name,
      primary_project = primary_project,
      sdk_version = forge.args["sdk-version"],
      template_name = forge.args.template,
      remotes = to_lash_string_array(remotes),
    }

    local files_to_render = {
      ".github/workflows/ci.yml",
      ".github/workflows/lint.yml",
      ".github/workflows/release.yml",
      "scripts/release/preflight.lash",
      "scripts/release/publish.lash",
    }

    for _, path in ipairs(files_to_render) do
      forge.tpl.render_file(path, path, vars)
    end

    chmod_executable(forge, "scripts/release/changelog_for_tag.bash")
    chmod_executable(forge, "scripts/release/preflight.lash")
    chmod_executable(forge, "scripts/release/publish.lash")

    forge.log.info(
      "Scaffolded .NET project " .. project_name .. " using dotnet new " .. forge.args.template
    )
  end,
}
