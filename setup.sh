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
# Usage: start_spinner "message"  →  stop_spinner [0=ok|1=fail]
_SPINNER_PID=""

start_spinner() {
    local msg="$1"
    # Run the dots animation in a background subshell
    (
        local dots=""
        while true; do
            for d in "." ".." "..."; do
                printf "\r  ${CYAN}${msg}${d}   ${NC}"
                sleep 0.4
            done
        done
    ) &
    _SPINNER_PID=$!
    # Suppress "Killed" job-control message
    disown "$_SPINNER_PID" 2>/dev/null
}

stop_spinner() {
    local status="${1:-0}"   # 0 = success/skip, 1 = error
    if [[ -n "$_SPINNER_PID" ]]; then
        kill "$_SPINNER_PID" 2>/dev/null
        wait "$_SPINNER_PID" 2>/dev/null
        _SPINNER_PID=""
    fi
    # Clear the spinner line
    printf "\r\033[2K"
    if [[ "$status" -eq 1 ]]; then
        echo -e "  [${RED}FAIL${NC}] Something went wrong."
    fi
}

# --- Helper: run a command silently while spinner runs ---
# run_with_spinner "Message" command [args…]
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
echo -e "\n${BOLD}${BLUE}╔══════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║     System Setup Starting    ║${NC}"
echo -e "${BOLD}${BLUE}╚══════════════════════════════╝${NC}\n"

# ── 1. Update the system ──────────────────────
echo -e "${BOLD}${CYAN}[1/6]${NC} System Update"
start_spinner "Updating package lists"
sudo apt-get update > /dev/null 2>&1
stop_spinner
echo -e "  [${GREEN}OK${NC}]   Package lists updated."

start_spinner "Upgrading packages"
sudo apt-get upgrade -y > /dev/null 2>&1
stop_spinner
echo -e "  [${GREEN}OK${NC}]   Packages upgraded.\n"

# ── 2. Install common tools ───────────────────
echo -e "${BOLD}${CYAN}[2/6]${NC} Common Tools"
PACKAGES=(curl git vim neovim zsh stow)
for pkg in "${PACKAGES[@]}"; do
    if is_installed "$pkg"; then
        echo -e "  [${GREEN}SKIP${NC}] $pkg already installed."
    else
        start_spinner "Installing $pkg"
        sudo apt-get install -y "$pkg" > /dev/null 2>&1
        stop_spinner
        echo -e "  [${YELLOW}DONE${NC}] $pkg installed."
    fi
done
echo ""

# ── 3. Install Oh-My-Zsh ─────────────────────
echo -e "${BOLD}${CYAN}[3/6]${NC} Oh-My-Zsh"
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo -e "  [${GREEN}SKIP${NC}] Oh-My-Zsh already installed.\n"
else
    start_spinner "Downloading & installing Oh-My-Zsh"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended > /dev/null 2>&1
    stop_spinner
    echo -e "  [${YELLOW}DONE${NC}] Oh-My-Zsh installed.\n"
fi

# ── 4. Define ZSH Custom path ─────────────────
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

# ── 5. Clone Zsh Plugins ──────────────────────
echo -e "${BOLD}${CYAN}[4/6]${NC} Zsh Plugins"

# Autosuggestions
if [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    echo -e "  [${GREEN}SKIP${NC}] zsh-autosuggestions already exists."
else
    start_spinner "Cloning zsh-autosuggestions"
    git clone https://github.com/zsh-users/zsh-autosuggestions \
        "$ZSH_CUSTOM/plugins/zsh-autosuggestions" > /dev/null 2>&1
    stop_spinner
    echo -e "  [${YELLOW}DONE${NC}] zsh-autosuggestions cloned."
fi

# Syntax Highlighting
if [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    echo -e "  [${GREEN}SKIP${NC}] zsh-syntax-highlighting already exists."
else
    start_spinner "Cloning zsh-syntax-highlighting"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
        "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" > /dev/null 2>&1
    stop_spinner
    echo -e "  [${YELLOW}DONE${NC}] zsh-syntax-highlighting cloned."
fi
echo ""

# ── 6. Configure .zshrc ───────────────────────
echo -e "${BOLD}${CYAN}[5/6]${NC} Zsh Configuration"
if grep -q "zsh-autosuggestions" "$HOME/.zshrc" 2>/dev/null; then
    echo -e "  [${GREEN}SKIP${NC}] Plugins already configured in .zshrc.\n"
else
    start_spinner "Updating .zshrc plugins"
    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc"
    stop_spinner
    echo -e "  [${YELLOW}DONE${NC}] .zshrc updated.\n"
fi

# ── 7. Change default shell ───────────────────
echo -e "${BOLD}${CYAN}[6/6]${NC} Default Shell"
if [[ "$SHELL" == *"zsh"* ]]; then
    echo -e "  [${GREEN}SKIP${NC}] Default shell is already zsh.\n"
else
    start_spinner "Changing default shell to zsh"
    sudo chsh -s "$(which zsh)" "$USER" > /dev/null 2>&1
    stop_spinner
    echo -e "  [${YELLOW}DONE${NC}] Default shell changed to zsh.\n"
fi

# ── Done ──────────────────────────────────────
echo -e "${BOLD}${BLUE}╔══════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║${NC}${BOLD}${GREEN}   ✓  Setup Complete!         ${NC}${BOLD}${BLUE}║${NC}"
echo -e "${BOLD}${BLUE}╚══════════════════════════════╝${NC}"
echo -e "  Restart your terminal to apply all changes.\n"
