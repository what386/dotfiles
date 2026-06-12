# config.nu
#
# Installed by:
# version = "0.110.0"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# Nushell sets "sensible defaults" for most configuration settings,
# so your `config.nu` only needs to override these defaults if desired.
#
# You can open this file in your default editor using:
#     config nu
#
# You can also pretty-print and page through the documentation for configuration
# options using:
#     config nu --doc | nu-highlight | less -R

use '/home/bmorin/.config/broot/launcher/nushell/br' *

source ~/.zoxide.nu

mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")

source ~/.local/share/atuin/init.nu

let fish_completer = {|spans|
    fish --command $"complete '--do-complete=($spans | str
    replace --all "'" "\\'" | str join ' ')'"
    | from tsv --flexible --noheaders --no-infer
    | rename value description
    | update value {|row|
        let value = $row.value
        let need_quote = ['\' ',' '[' ']' '(' ')' ' ' '\t' "'"
        '"' "`"] | any {$in in $value}

        if ($need_quote and ($value | path exists)) {
          let expanded_path = if ($value starts-with ~) {
              $value | path expand --no-symlink
          } else {
              $value
          }

          $'"($expanded_path | str replace --all "\"" "\\\"")"'
        } else {
          $value
        }
    }
}

$env.config.completions.external.enable = true
$env.config.completions.external.completer = $fish_completer

const upstream_paths_nu = if ("~/.upstream/metadata/paths.nu" | path expand | path exists) { ("~/.upstream/metadata/paths.nu" | path expand) } else { null }
source-env $upstream_paths_nu

alias cd = z
