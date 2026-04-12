#!/bin/bash

# --- Color Definitions ---
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color (Reset)

# --- Spinner / Animated Dots ---
_SPINNER_PID=""

start_spinner() {
    local msg="$1"
    (
        while true; do
            for d in "." ".." "..."; do
                printf "\r  ${CYAN}${msg}${d}   ${NC}"
                sleep 0.4
            done
        done
    ) &
    _SPINNER_PID=$!
    disown "$_SPINNER_PID" 2>/dev/null
}

stop_spinner() {
    local status="${1:-0}"
    if [[ -n "$_SPINNER_PID" ]]; then
        kill "$_SPINNER_PID" 2>/dev/null
        wait "$_SPINNER_PID" 2>/dev/null
        _SPINNER_PID=""
    fi
    printf "\r\033[2K"
    if [[ "$status" -eq 1 ]]; then
        echo -e "  [${RED}FAIL${NC}] Something went wrong."
    fi
}

# --- Helper: ask a yes/no question ---
ask_yn() {
    local prompt="$1"
    local answer
    echo -en "  ${CYAN}?${NC} ${prompt} (y/N): "
    read -r answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

# --- Helper: run a command silently with spinner ---
run_with_spinner() {
    local msg="$1"; shift
    start_spinner "$msg"
    "$@" > /dev/null 2>&1
    local rc=$?
    stop_spinner $rc
    return $rc
}

# Function to check if a package is installed
is_installed() {
    command -v "$1" > /dev/null 2>&1
}

# ─────────────────────────────────────────────
# Pre-flight: Get sudo password upfront
if ! sudo -n true 2>/dev/null; then
    echo -e "${CYAN}Please enter your password to grant sudo access:${NC}"
    sudo -v
fi
# Keep sudo alive in the background
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_KEEPALIVE_PID=$!

# ─────────────────────────────────────────────
echo -e "\n${BOLD}${BLUE}╔══════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║     System Setup Starting    ║${NC}"
echo -e "${BOLD}${BLUE}╚══════════════════════════════╝${NC}\n"
echo -e "  You will be asked before ${BOLD}each${NC} step. Press ${YELLOW}y${NC} to accept or ${RED}Enter${NC} to skip.\n"

# ── 1. Update the system ──────────────────────
echo -e "${BOLD}${CYAN}[1/8]${NC} System Update"
if ask_yn "Update and upgrade system packages?"; then
    run_with_spinner "Updating package lists" sudo apt-get update
    echo -e "  [${GREEN}OK${NC}]   Package lists updated."
    run_with_spinner "Upgrading packages" sudo apt-get upgrade -y
    echo -e "  [${GREEN}OK${NC}]   Packages upgraded."
else
    echo -e "  [${GREEN}SKIP${NC}] System update skipped."
fi
echo ""

# ── 2. Install common tools ───────────────────
echo -e "${BOLD}${CYAN}[2/8]${NC} Common Tools"
echo -e "  You will be asked for each package individually.\n"

ALL_PACKAGES=(curl git vim neovim zsh stow wezterm tmux eza)

echo -e "  ${CYAN}?${NC} Enter any extra packages to install (space-separated), or press Enter to skip:"
read -rp "    Extra packages: " extra_input
if [[ -n "$extra_input" ]]; then
    read -ra EXTRA_PACKAGES <<< "$extra_input"
    ALL_PACKAGES+=("${EXTRA_PACKAGES[@]}")
fi
echo ""

for pkg in "${ALL_PACKAGES[@]}"; do
    if is_installed "$pkg"; then
        echo -e "  [${GREEN}SKIP${NC}] $pkg is already installed."
    else
        if ask_yn "Install ${BOLD}${pkg}${NC}?"; then
            run_with_spinner "Installing $pkg" sudo apt-get install -y "$pkg"
            echo -e "  [${YELLOW}DONE${NC}] $pkg installed."
        else
            echo -e "  [${GREEN}SKIP${NC}] $pkg skipped."
        fi
    fi
done
echo ""

# ── 3. Install Oh-My-Zsh ─────────────────────
echo -e "${BOLD}${CYAN}[3/8]${NC} Oh-My-Zsh"
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo -e "  [${GREEN}SKIP${NC}] Oh-My-Zsh already installed."
else
    if ask_yn "Install Oh-My-Zsh?"; then
        run_with_spinner "Downloading & installing Oh-My-Zsh" \
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        echo -e "  [${YELLOW}DONE${NC}] Oh-My-Zsh installed."
    else
        echo -e "  [${GREEN}SKIP${NC}] Oh-My-Zsh skipped."
    fi
fi
echo ""

# ── 4. Clone Zsh Plugins ──────────────────────
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

echo -e "${BOLD}${CYAN}[4/8]${NC} Zsh Plugins"

# Autosuggestions
if [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    echo -e "  [${GREEN}SKIP${NC}] zsh-autosuggestions already exists."
else
    if ask_yn "Clone ${BOLD}zsh-autosuggestions${NC}?"; then
        run_with_spinner "Cloning zsh-autosuggestions" \
            git clone https://github.com/zsh-users/zsh-autosuggestions \
            "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
        echo -e "  [${YELLOW}DONE${NC}] zsh-autosuggestions cloned."
    else
        echo -e "  [${GREEN}SKIP${NC}] zsh-autosuggestions skipped."
    fi
fi

# Syntax Highlighting
if [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    echo -e "  [${GREEN}SKIP${NC}] zsh-syntax-highlighting already exists."
else
    if ask_yn "Clone ${BOLD}zsh-syntax-highlighting${NC}?"; then
        run_with_spinner "Cloning zsh-syntax-highlighting" \
            git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
            "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
        echo -e "  [${YELLOW}DONE${NC}] zsh-syntax-highlighting cloned."
    else
        echo -e "  [${GREEN}SKIP${NC}] zsh-syntax-highlighting skipped."
    fi
fi
echo ""

# ── 5. Configure .zshrc ───────────────────────
echo -e "${BOLD}${CYAN}[5/8]${NC} Zsh Configuration"
if grep -q "zsh-autosuggestions" "$HOME/.zshrc" 2>/dev/null; then
    echo -e "  [${GREEN}SKIP${NC}] Plugins already configured in .zshrc."
else
    if ask_yn "Update .zshrc to enable the cloned plugins?"; then
        sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc"
        echo -e "  [${YELLOW}DONE${NC}] .zshrc updated."
    else
        echo -e "  [${GREEN}SKIP${NC}] .zshrc update skipped."
    fi
fi
echo ""

# ── 6. Change default shell ───────────────────
echo -e "${BOLD}${CYAN}[6/8]${NC} Default Shell"
if [[ "$SHELL" == *"zsh"* ]]; then
    echo -e "  [${GREEN}SKIP${NC}] Default shell is already zsh."
else
    if ask_yn "Change your default shell to ${BOLD}zsh${NC}?"; then
        run_with_spinner "Changing default shell to zsh" \
            sudo chsh -s "$(which zsh)" "$USER"
        echo -e "  [${YELLOW}DONE${NC}] Default shell changed to zsh."
    else
        echo -e "  [${GREEN}SKIP${NC}] Default shell unchanged."
    fi
fi
echo ""

# ── 7. Install Nerd Font ──────────────────────
echo -e "${BOLD}${CYAN}[7/8]${NC} JetBrainsMono Nerd Font"
if fc-list | grep -qi "JetBrainsMono Nerd Font"; then
    echo -e "  [${GREEN}SKIP${NC}] JetBrainsMono Nerd Font is already installed."
else
    if ask_yn "Download and install JetBrainsMono Nerd Font?"; then
        start_spinner "Downloading JetBrainsMono font"
        mkdir -p "$HOME/.local/share/fonts"
        curl -fLo "$HOME/.local/share/fonts/JetBrainsMonoNerdFont-Regular.ttf" \
            https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/JetBrainsMono/Ligatures/Regular/JetBrainsMonoNerdFont-Regular.ttf > /dev/null 2>&1
        fc-cache -fv > /dev/null 2>&1
        stop_spinner
        echo -e "  [${YELLOW}DONE${NC}] JetBrainsMono Nerd Font installed."
        echo -e "         ${CYAN}Note: Select it manually in your terminal emulator preferences.${NC}"
    else
        echo -e "  [${GREEN}SKIP${NC}] Font installation skipped."
    fi
fi
echo ""

# ── 8. Clone Dotfiles & Stow ──────────────────
DOTFILES_REPO="https://github.com/aziddineelm/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"

echo -e "${BOLD}${CYAN}[8/8]${NC} Dotfiles"
if [ -d "$DOTFILES_DIR" ]; then
    echo -e "  [${GREEN}SKIP${NC}] Dotfiles directory already exists at $DOTFILES_DIR."
    if ask_yn "Re-run ${BOLD}stow .${NC} to relink configs?"; then
        run_with_spinner "Stowing dotfiles" stow -d "$DOTFILES_DIR" -t "$HOME" .
        echo -e "  [${YELLOW}DONE${NC}] Dotfiles re-stowed."
    fi
else
    if ask_yn "Clone dotfiles and link configs with stow?"; then
        run_with_spinner "Cloning dotfiles" git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
        echo -e "  [${YELLOW}DONE${NC}] Dotfiles cloned to $DOTFILES_DIR."
        run_with_spinner "Stowing dotfiles" stow -d "$DOTFILES_DIR" -t "$HOME" .
        echo -e "  [${YELLOW}DONE${NC}] Dotfiles stowed (config symlinks created)."
    else
        echo -e "  [${GREEN}SKIP${NC}] Dotfiles skipped."
    fi
fi
echo ""

# ── Done ──────────────────────────────────────
echo -e "${BOLD}${BLUE}╔══════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║${NC}${BOLD}${GREEN}   ✓  Setup Complete!         ${NC}${BOLD}${BLUE}║${NC}"
echo -e "${BOLD}${BLUE}╚══════════════════════════════╝${NC}"
echo -e "  Restart your terminal (or run ${CYAN}source ~/.zshrc${NC}) to apply all changes.\n"
