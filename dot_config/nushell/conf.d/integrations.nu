let vendor_dir = ($nu.default-config-dir | path join "vendor")

mkdir $vendor_dir

def init [program: string, command: closure] {
  let vendor_file = ($vendor_dir | path join $"($program).nu")

  do $command | save -f $vendor_file
}

init zoxide { zoxide init nushell }
init starship { starship init nu }

source ~/.config/nushell/vendor/zoxide.nu
source ~/.config/nushell/vendor/starship.nu

source ~/.local/share/atuin/init.nu
use '/home/bmorin/.config/broot/launcher/nushell/br' *
