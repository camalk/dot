#!/usr/bin/env bash
set -euo pipefail

OS=$(uname -s | tr "[:upper:]" "[:lower:]")
ARCH=$(uname -m)
DEPS=(
    "git"
    "stow"
)

NERD_FONT_BASE_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"
NERD_FONTS=(
    "IBMPlexMono"
    "IosevkaTermSlab"
)

# helper functions
# ===========================================
assert() {
    if [[ "$#" -lt 1 ]]; then
        echo "error: assert() requires at least 1 argument" >&2
        echo "usage:"
        echo "  assert <condition> <errormessage?>"
        exit 1
    fi

    local message="${@: -1}"        # last arg is message
    local predicate=("${@:1:$#-1}") # all but last arg is predicate
    if ! eval "${predicate[*]}"; then
        echo "error: assertion failed with status $?. $message" >&2
        exit 1
    fi
}

installed() {
    if [[ "$#" -ne 1 ]]; then
        echo "error: installed() requires exactly one argument" >&2
        exit 1
    fi
    command -v "$1" &>/dev/null
}

is_mac() {
    [[ "$OS" == "darwin" ]]
}

is_arm64() {
    [[ "$ARCH" == "arm64" ]]
}

repo_root_dir() {
    git rev-parse --show-toplevel
}

pwd_is_repo_root_dir() {
    [[ $(pwd) == $(repo_root_dir) ]]
}

font_path() {
    case $OS in
    "darwin")
        echo "$HOME/Library/Fonts"
        ;;
    "linux")
        echo "$XDG_DATA_HOME/fonts"
        ;;
    *)
        echo "error: unsupported os ('$OS') has no font path specified" >&2
        return 1
        ;;
    esac
}

# impl
# ===========================================
missing=()
if ! installed sudo; then missing+=("sudo"); fi

for dep in "${DEPS[@]}"; do
    installed "$dep" || missing+=("$dep")
done

if [[ ${#missing[@]} -gt 0 ]]; then
    echo "error: missing dependencies: ${missing[*]}" >&2
    exit 1
fi

setup_nerd_fonts() {
    echo "info: installing fonts"

    # dont declare and assign in one, local * doesnt propagate exit codes
    local os_aware_font_path
    os_aware_font_path=$(font_path) || {
        echo "warning: skipping fonts" >&2
        return 0
    }

    for font in "${NERD_FONTS[@]}"; do
        local tmp_dir=$(mktemp -d -t "$font")
        if [[ -f "${os_aware_font_path}/${font}-Regular.ttf" ]]; then
            echo "info: font $font seems to already exist in $os_aware_font_path. skipping installation"
        else
            echo "info: installing font $font to $os_aware_font_path via tmp dir $tmp_dir"
            local dl_path="/tmp/${font}.tar.xz"
            curl -fsSL "${NERD_FONT_BASE_URL}/${font}" -o "$dl_path"
            tar -xf "$dl_path" --directory "$tmp_dir"

            # only keep the 'normal' fonts, not the 'variants' like Mono, MonoPropo, Propo etc.
            cp "${tmp_dir}/${font}"-*.ttf "$os_aware_font_path"

            # update font cache
            [[ "$OS" == "linux" ]] && fc-cache -fv

            rm -rf "${tmp_dir}" "${dl_path}"
        fi
    done
}

setup_homebrew() {
    assert is_mac "cannot call setup_homebrew() on non-macOS: detected $OS"

    if is_arm64; then BREW_PREFIX="/opt/homebrew" else BREW_PREFIX="/usr/local"; fi

    if installed brew; then
        echo "info: found existing homebrew installation: $(brew -v)"
    else
        echo "info: installing homebrew"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        eval "$(${BREW_PREFIX}/bin/brew shellenv)"
    fi
}

setup_git() {
    assert installed git "cannot proceed with setup_git(). git installation not found"

    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"

    # https://jvns.ca/blog/2024/02/16/popular-git-config-options/
    git config --global diff.algorithm histogram
    git config --global push.autoSetupRemote true
    git config --global rebase.autosquash true
    git config --global rebase.autostash true
    git config --global merge.conflictStyle zdiff3

    # use `git clone gh:owner/repo`
    git config --global url."git@github.com:".insteadOf "gh:"

    if [[ "$OS" == "darwin" ]]; then
        git config --global credential.helper osxkeychain
    fi
}

stow_files() {
    assert pwd_is_repo_root_dir "$PWD does not match expected root dir $(repo_root_dir). some commands may not work as expected"
    stow --target="$HOME/.config" --no-folding ./config
    stow --target="$HOME/.local/bin" --no-folding ./bin
}

# os setup
# ===========================================
setup_mac() {
    assert is_mac "cannot call setup_mac() on non-macOS: detected $OS"

    echo "info: installing xcode-select command line tools"
    if xcode-select -p &>/dev/null; then
        echo "info: found existing xcode-select cli tools installation at $(xcode-select -p)"
    else
        echo "info: starting xcode-select command line tools installation. please approve the dialog..."
        xcode-select --install &
        sleep 5
    fi

    # setup_homebrew
    # setup_nerd_fonts
    # stow_files
}

setup_mac
