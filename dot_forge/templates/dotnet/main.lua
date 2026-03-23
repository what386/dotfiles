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
			"dotnet new "
				.. shell_quote(forge.args.template)
				.. " -n "
				.. shell_quote(primary_project)
				.. " --no-restore -o "
				.. shell_quote("src/" .. primary_project)
		)
		forge.exec.run(
			"dotnet new xunit -n "
				.. shell_quote(tests_project)
				.. " --no-restore -o "
				.. shell_quote("tests/" .. tests_project)
		)

		forge.exec.run(
			"dotnet sln add "
				.. shell_quote("src/" .. primary_project .. "/" .. primary_project .. ".csproj")
				.. " "
				.. shell_quote("tests/" .. tests_project .. "/" .. tests_project .. ".csproj")
		)
		forge.exec.run(
			"dotnet add "
				.. shell_quote("tests/" .. tests_project .. "/" .. tests_project .. ".csproj")
				.. " reference "
				.. shell_quote("src/" .. primary_project .. "/" .. primary_project .. ".csproj")
		)

		forge.exec.run("git init")
		forge.exec.run("tally init")

		forge.exec.run('git add ."')
		forge.exec.run('git commit -m "initial commit"')

		forge.log.info("Scaffolded .NET project " .. project_name .. " using dotnet new " .. forge.args.template)
	end,
}
