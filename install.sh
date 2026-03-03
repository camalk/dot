#!/usr/bin/env bash

# pre
# ===========================================
#
# I've tried to make these various installation steps
# composable and (wherever possible) idempotent.
set -euo pipefail

OS=$(uname -s | tr "[:upper:]" "[:lower:]")
ARCH=$(uname -m)
DEPS=(
    "git"
    "stow"
)

NERD_FONT_BASE_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"
NERD_FONTS=(
    "IosevkaTermSlab"
)

# helper functions
# ===========================================
failwith() {
    if [[ "$#" -lt 1 ]]; then
        echo "error: failwith() requires at least 1 argument: usage: failwith <message> <exitcode?>" >&2
        exit 1
    fi
    echo "$1" >&2
    exit "${2:-1}"
}

installed() {
    [[ "$#" -ne 1 ]] || failwith "error: installed() requires exactly one argument: usage: installed <command>"
    command -v "$1" &>/dev/null
}

is_mac() { [[ "$OS" == "darwin" ]]; }
is_arm64() { [[ "$ARCH" == "arm64" ]]; }
repo_root_dir() { git rev-parse --show-toplevel; }
pwd_is_repo_root_dir() { [[ $(pwd) == $(repo_root_dir) ]]; }

font_path() {
    case $OS in
    "darwin") echo "$HOME/Library/Fonts" ;;
    "linux") echo "${XDG_DATA_HOME:-$HOME/.local/share}/fonts" ;;
    *)
        echo "error: unsupported os ('$OS') has no font path specified" >&2
        return 1
        ;;
    esac
}

nerd_font_installed() {
    [[ "$#" -ne 2 ]] ||
        failwith "error: nerd_font_installed() requires exactly 2 arguments: usage: nerd_font_installed <font> <install_path>"

    local font="$1"
    local install_path="$2"
    [[ -f "${install_path}/${font}-Regular.ttf" ]]
}

install_nerd_font() {
    [[ "$#" -ne 2 ]] ||
        failwith "error: download_nerd_font() requires exactly 2 arguments: usage: download_nerd_font <font> <install_path>"

    local font="$1"
    local install_path="$2"

    local font_link="${NERD_FONT_BASE_URL}/${font}"
    local download_path="/tmp/${font}.tar.xz"
    local extract_dir=$(mktemp -d -t "$font")

    curl -fsSL "$font_link" -o "$download_path" || {
        echo "error: failed downloading $font" >&2
        rm -rf "${extract_dir}" # cleanup
        continue
    }

    tar -xf "$download_path" --directory "$extract_dir"
    cp "${extract_dir}/${font}"-*.ttf "$install_path" # ignore Mono, Propo variants etc.

    [[ "$OS" == "linux" ]] && fc-cache -fv # update linux font cache

    rm -rf "${extract_dir}" "${download_path}" # cleanup
}

# impl
# ===========================================
ensure_fonts() {
    echo "info: installing nerd fonts"

    local fp
    fp=$(font_path) || {
        echo "warning: skipping fonts" >&2
        return 0
    }

    for font in "${NERD_FONTS[@]}"; do
        nerd_font_installed "$fp" "$font" && {
            echo "$font already exists in $fp. skipping"
            continue
        }

        echo "info: installing font $font to $fp"
        install_nerd_font "$font" "$fp"
    done
}

setup_homebrew() {
    is_mac || failwith "cannot call setup_homebrew() on non-macOS: detected $OS"

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
    installed git || failwith "cannot proceed with setup_git(). git installation not found"

    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"

    # https://jvns.ca/blog/2024/02/16/popular-git-config-options/
    git config --global diff.algorithm histogram
    git config --global push.autoSetupRemote true
    git config --global rebase.autosquash true
    git config --global rebase.autostash true
    git config --global merge.conflictStyle zdiff3
    git config --global url."git@github.com:".insteadOf "gh:" # use `git clone gh:owner/repo`

    is_mac && git config --global credential.helper osxkeychain

}

stow_files() {
    pwd_is_repo_root_dir ||
        failwith "$PWD does not match expected root dir $(repo_root_dir). some commands may not work as expected"
    stow --target="$HOME/.config" --no-folding ./config
    stow --target="$HOME/.local/bin" --no-folding ./bin
}

# os setup
# ===========================================
setup_mac() {
    is_mac || failwith "cannot call setup_mac() on non-macOS: detected $OS"

    echo "info: installing xcode-select command line tools"
    if xcode-select -p &>/dev/null; then
        echo "info: found existing xcode-select cli tools installation at $(xcode-select -p)"
    else
        echo "info: starting xcode-select command line tools installation. please approve the dialog..."
        xcode-select --install &
        sleep 5
    fi

    setup_homebrew
    ensure_fonts
    stow_files
}

# entry
# ===========================================
main() {
    missing=()
    if ! installed sudo; then missing+=("sudo"); fi

    for dep in "${DEPS[@]}"; do
        installed "$dep" || missing+=("$dep")
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "error: missing dependencies: ${missing[*]}" >&2
        exit 1
    fi

    case "$OS" in
    "darwin") setup_mac ;;
    "linux") echo "todo" ;;
    *)
        echo "unsupported os: $OS" >&2
        exit 1
        ;;
    esac
}

main "$@"
