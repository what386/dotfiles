if status is-interactive
    # Commands to run in interactive sessions can go here
end

zoxide init fish | source

# PATH additions
set -gx PATH $PATH /usr/local/go/bin
set -gx GOPATH $HOME/.go
set -gx PATH $PATH $GOPATH/bin
set -gx PATH $PATH /opt/yazi-x86_64-unknown-linux-gnu
set -gx PATH $PATH /opt/zen
set -gx PATH $PATH /opt/FlexBVFree-5.1119-linux
set -gx PATH $PATH /opt/blender-4.4.0-linux-x64
