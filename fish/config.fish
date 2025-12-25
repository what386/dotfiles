source $HOME/.upstream/metadata/paths.sh

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

set -gx PATH $PATH /opt/zen
set -gx PATH $PATH /opt/zig-x86_64-linux-0.16.0-dev.1657+985a3565c

direnv hook fish | source

