return {
	run = function(forge)
		forge.tpl.render_file("xmake.lua", "xmake.lua", {
			name = forge.args.name,
		})

		forge.exec.run("git init")
		forge.exec.run("tally init")

		forge.exec.run('git add ."')
		forge.exec.run('git commit -m "initial commit"')

		forge.log.info("Scaffolded " .. forge.args.name)
	end,
}
