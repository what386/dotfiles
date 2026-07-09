source $HOME/.upstream/metadata/paths.sh
fish_add_path ~/.local/bin

if status is-interactive
    # Commands to run in interactive sessions can go here
    atuin init fish | source
end

# ASDF configuration code
if test -z $ASDF_DATA_DIR
    set _asdf_shims "$HOME/.asdf/shims"
else
    set _asdf_shims "$ASDF_DATA_DIR/shims"
end

# Do not use fish_add_path (added in Fish 3.2) because it
# potentially changes the order of items in PATH
if not contains $_asdf_shims $PATH
    set -gx --prepend PATH $_asdf_shims
end
set --erase _asdf_shims

zoxide init fish | source

# PATH additions

set -gx DOTNET_ROOT $HOME/.dotnet
fish_add_path $HOME/.dotnet

direnv hook fish | source

set -U fish_user_paths /nix/var/nix/profiles/default/bin $fish_user_paths

starship init fish | source

source ~/Android/env.fish

test -f $HOME/.upstream/generated/paths.sh; and source $HOME/.upstream/generated/paths.sh
