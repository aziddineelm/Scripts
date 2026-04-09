# Script Collection

This directory contains a collection of helpful Bash and Zsh scripts to improve workflow, automate system provisioning, and enhance security.

## Included Scripts

### 1. `setup.sh` (System Setup & Provisioning)

A comprehensive setup script that automates the installation of essential packages and standardizes the terminal environment. It features a rich, animated UI to guide you through the process.

**What it does:**
- Updates and upgrades system packages via `apt-get`
- Installs common development tools: `curl`, `git`, `vim`, `neovim`, `zsh`, `stow`
- Installs [Oh-My-Zsh](https://ohmyzsh.sh/) if it's not already installed
- Automatically clones useful Zsh plugins:
  - `zsh-autosuggestions`
  - `zsh-syntax-highlighting`
- Configures `~/.zshrc` to enable the cloned plugins
- Changes the user's default shell to `zsh`

**Usage:**
```bash
# Make it executable (only needed once)
chmod +x ./setup.sh

# Run the setup script
./setup.sh
```

---

### 2. `gasp.sh` (Git Add, Commit, Push)

A simple, fast wrapper script around the most common Git workflow, allowing you to stage, commit, and push in one fluid motion without typing multiple commands.

**What it does:**
- Stages all changes in the current directory (`git add .`)
- Prompts you for a commit message
- Commits the staged changes with your message
- Pushes the branch to the remote repository

**Usage:**
```bash
# Execute from within any git repository
./gasp.sh
```
*Note: You may want to alias this in your `.zshrc` or `.bashrc` for even quicker access (e.g., `alias gasp="~/Scripts/gasp.sh"`).*

---

### 3. `telelock.sh` (Proximity USB Unlocker)

A security and convenience daemon script written in Zsh. It monitors your USB connections and automatically unlocks the session when a trusted device (like your phone) is plugged in.

**What it does:**
- Runs as a background loop checking `lsusb` every 2 seconds.
- Looks for a specific USB device ID defined by the `$MYPHONEID` environment variable.
- When the device is detected, it automatically kills the screen locker (`ft_lock`) and displays a desktop notification.
- Manages state using a temporary lockfile (`/tmp/telelock`) to ensure it only triggers once per plug-in.

**Requirements & Configuration:**
Before running `telelock.sh`, you must find your phone's USB ID using the `lsusb` command, and export it in your `~/.zshrc`:
```bash
# In your ~/.zshrc
export MYPHONEID="1234:abcd"  # Replace with your actual device ID
```

**Usage:**
```bash
# Run the daemon (it automatically pushes itself to the background)
./telelock.sh
```
