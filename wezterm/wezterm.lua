local Config = require("config")

--require('events.left-status').setup()
--require('events.right-status').setup({ date_format = '%a %H:%M:%S' })
--require('events.tab-title').setup({ hide_active_tab_unseen = false, unseen_icon = 'circle' })
--require('events.new-tab-button').setup()

return Config:init()
	:append(require("config.keymaps"))
	:append(require("config.options"))
	:append(require("config.domains"))
	:append(require("theme.fonts"))
	:append(require("theme.colors"))
	:append(require("theme.appearance"))
	:append(require("theme.tabline"))
	:append(require("config.launch")).options
