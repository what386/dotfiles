local function shell_quote(value)
  local text = tostring(value)
  return "'" .. text:gsub("'", "'\\''") .. "'"
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
    cli:option("remotes", {
      type = "string",
      default = "github,gitea",
      help = "Comma- or space-separated git remotes used in release scripts",
    })
  end,

  run = function(forge)
    forge.exec.run(
      "cargo init --bin --vcs none --name " .. shell_quote(forge.args.name) .. " ."
    )

    local remotes = parse_remotes(forge.args.remotes)

    local vars = {
      project_name = forge.args.name,
      project_slug = forge.args.name,
      project_binary = forge.args.name,
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

    forge.log.info("Scaffolded Rust project " .. forge.args.name)
  end,
}
