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
		forge.tpl.render_file(".github/workflows/release.yml", ".github/workflows/release.yml", {
			binary_name = forge.args.name,
		})

		forge.tpl.render_file(".github/DISCUSSION_TEMPLATE/support_request.yml", ".github/DISCUSSION_TEMPLATE/support_request.yml", { binary_name = forge.args.name })
		forge.tpl.render_file(".github/ISSUE_TEMPLATE/bug_report.yml", ".github/ISSUE_TEMPLATE/bug_report.yml", { binary_name = forge.args.name })
		forge.tpl.render_file(".github/ISSUE_TEMPLATE/feature_request.yml", ".github/ISSUE_TEMPLATE/feature_request.yml", { binary_name = forge.args.name })

		forge.exec.run("cargo init --bin --vcs none --name " .. shell_quote(forge.args.name) .. " .")

		forge.exec.run("git init")
		forge.exec.run("tally init")

		forge.exec.run("git add .")
		forge.exec.run('git commit -m "initial commit"')

		forge.log.info("Scaffolded Rust project " .. forge.args.name)
	end,
}
