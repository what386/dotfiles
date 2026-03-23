local function shell_quote(value)
	local text = tostring(value)
	return "'" .. text:gsub("'", "'\\''") .. "'"
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
		forge.exec.run("cargo init --bin --vcs none --name " .. shell_quote(forge.args.name) .. " .")

		forge.exec.run("git init")
		forge.exec.run("tally init")

		forge.exec.run("git add .")
		forge.exec.run('git commit -m "initial commit"')

		forge.log.info("Scaffolded Rust project " .. forge.args.name)
	end,
}
