# program abbrs
abbr n nvim
abbr lg lazygit
abbr lado lazydocker
abbr , z
abbr e yazi

# git
abbr gco "git checkout"
abbr gcb "git checkout -b"
abbr glo "git log --oneline --all"
abbr gfap "git fetch --all --prune"
abbr gpo "git push -u origin"

#better rm
abbr rm rip

# tmux
abbr tk "tmux kill-server"
abbr ta "tmux a"
abbr tat "tmux attach -t"
abbr td "t dotfiles"
abbr tn "tmux new -s (basename (pwd))"

# micromamba
abbr mam micromamba
abbr mc "micromamba create"
abbr ma "micromamba activate"
abbr md "micromamba deactivate"
abbr mae 'micromamba activate | fzf --query="$1" -m --preview "micromamba env list"'
abbr mi "micromamba install"
# man-style pages with tldr
abbr toolong "tldr --list | fzf --header 'I ain readin allat' --reverse --preview 'tldr {1}' --preview-window=right,80% | xargs tldr"

#pnpm
abbr pp pnpm

#homebrew
abbr update "brew outdated | fzf --multi --reverse | xargs brew upgrade"

# find files with neovim
abbr fo "fd --type f --hidden --ignore-file ~/.config/fd/vimignore | fzf | xargs nvim"

# codecrafters
abbr ccs "codecrafters submit"
abbr cct "codecrafters test"

# opentofu
abbr tf tofu
abbr tfi "tofu init"
abbr tfv "tofu validate"
abbr tfp "tofu plan"
abbr tfa "tofu apply"
abbr tfd "tofu destroy"
abbr tfm "tofu fmt --recursive"

# docker
abbr dkc "docker compose"
abbr dkcd "docker compose down"
abbr dkps "docker ps -a"
abbr dklf "docker logs --follow"
