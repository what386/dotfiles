return {
  run = function(forge)
    forge.tpl.render_file("xmake.lua", "xmake.lua", {
      name = forge.args.name,
    })
    forge.log.info("Scaffolded " .. forge.args.name)
  end,
}
