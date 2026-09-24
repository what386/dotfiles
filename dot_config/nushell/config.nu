# ~/.config/nushell/config.nu

$env.config.history.path = "/dev/null"

const NU_CONFIG_DIR = $nu.default-config-dir

source ($NU_CONFIG_DIR | path join "conf.d/hooks.nu")
source ($NU_CONFIG_DIR | path join "conf.d/integrations.nu")
source ($NU_CONFIG_DIR | path join "conf.d/completions.nu")
source ($NU_CONFIG_DIR | path join "conf.d/aliases.nu")

source ($NU_CONFIG_DIR | path join "conf.d/commands.nu")
source ($NU_CONFIG_DIR | path join "conf.d/variables.nu")
source ($NU_CONFIG_DIR | path join "conf.d/paths.nu")
source ($NU_CONFIG_DIR | path join "conf.d/compatibility.nu")

source ($NU_CONFIG_DIR | path join "conf.d/autoexec.nu")

const upstream_paths_nu = if ("~/.upstream/generated/paths.nu" | path expand | path exists) { ("~/.upstream/generated/paths.nu" | path expand) } else { null }; source-env $upstream_paths_nu
