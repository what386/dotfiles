# ~/.config/nushell/config.nu

$env.config.history.path = "/dev/null"

source ~/.config/nushell/conf.d/integrations.nu
source ~/.config/nushell/conf.d/completions.nu
source ~/.config/nushell/conf.d/aliases.nu
source ~/.config/nushell/conf.d/hooks.nu

const upstream_paths_nu = if ("~/.upstream/metadata/paths.nu" | path expand | path exists) { ("~/.upstream/metadata/paths.nu" | path expand) } else { null }; source-env $upstream_paths_nu
