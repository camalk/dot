if status is-interactive
    # Commands to run in interactive sessions can go here
    starship init fish | source
    zoxide init fish | source
    atuin init fish --disable-up-arrow | source
    fnm env --use-on-cd --shell fish --corepack-enabled | source
end

fish_add_path ~/.cargo/bin
fish_add_path ~/.config/tmux/plugins/tpm/bin
fish_add_path ~/.config/tmux/plugins/t-smart-tmux-session-manager/bin
fish_add_path ~/.local/share/bob/nvim-bin
fish_add_path ~/.local/bin
fish_add_path ~/go/bin
fish_add_path ~/.zig

set -gx EDITOR nvim
set -gx STARSHIP_CONFIG ~/.config/starship/starship.toml
set -gx fish_greeting #disable greeting

if type -q nvim
    set -gx MANPAGER "nvim +Man!"
end

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init2.fish 2>/dev/null || :

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# BEGIN opam configuration
# This is useful if you're using opam as it adds:
#   - the correct directories to the PATH
#   - auto-completion for the opam binary
# This section can be safely removed at any time if needed.
test -r '/Users/cameron/.opam/opam-init/init.fish' && source '/Users/cameron/.opam/opam-init/init.fish' >/dev/null 2>/dev/null; or true
# END opam configuration

# pnpm
set -gx PNPM_HOME "/Users/cameron/Library/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end
