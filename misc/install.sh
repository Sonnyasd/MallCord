#!/usr/bin/env bash
# ================================================
# Private MallCord Advanced Installer (Linux/macOS)
# Usage: bash install.sh
# ================================================

set -o pipefail

REPO_URL="https://github.com/Sonnyasd/MallCord"
INSTALL_DIR="$HOME/PrivateMallCord"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

print_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                 ${GREEN}Private MallCord Setup${NC}                 ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
}

step() { echo -e "${CYAN}➜${NC} $*"; }
ok()   { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}!${NC} $*"; }
error(){ echo -e "${RED}✖${NC} $*"; }

close_discord() {
    step "Closing Discord processes..."
    pkill -f Discord 2>/dev/null || true
    pkill -f "discord" 2>/dev/null || true
    sleep 2
}

# ===================== MAIN MENU =====================
print_header

echo -e "   ${CYAN}What would you like to do?${NC}"
echo
echo -e "   ${GREEN}[1]${NC} Install / Update"
echo -e "   ${GREEN}[2]${NC} Check for Updates"
echo -e "   ${GREEN}[3]${NC} Uninstall"
echo -e "   ${GREEN}[4]${NC} Exit"
echo
read -p "   Choose an option [1-4]: " CHOICE

case $CHOICE in
    4) exit 0 ;;
    3) exec bash -c "
        if [ ! -d \"$INSTALL_DIR\" ]; then
            echo -e \"${RED}Private MallCord not found.${NC}\"
            exit 1
        fi
        close_discord
        cd \"$INSTALL_DIR\"
        step \"Removing from Discord...\"
        node scripts/runInstaller.mjs -- --uninstall || warn \"Uninject had some issues.\"
        echo
        read -p \"   Also delete the PrivateMallCord folder? [y/N]: \" DEL
        if [[ \$DEL =~ ^[Yy]$ ]]; then
            rm -rf \"$INSTALL_DIR\"
            ok \"Folder deleted.\"
        fi
        echo -e \"${GREEN}Private MallCord uninstalled. Restart Discord.${NC}\"
        " ;;
    2)
        if [ ! -d "$INSTALL_DIR/.git" ]; then
            error "Private MallCord is not installed yet."
            exit 1
        fi
        cd "$INSTALL_DIR"
        step "Checking for updates..."
        git fetch origin main
        echo
        git log HEAD..origin/main --oneline
        echo
        read -p "   Update now? [y/N]: " UPD
        if [[ $UPD =~ ^[Yy]$ ]]; then
            close_discord
            git reset --hard origin/main
            step "Installing dependencies..."
            pnpm install --frozen-lockfile
            step "Building..."
            pnpm build
            step "Injecting into Discord..."
            node scripts/runInstaller.mjs -- --install
            ok "Update completed successfully!"
        fi
        exit 0
        ;;
esac

# ===================== INSTALL / UPDATE =====================
[[ $EUID -eq 0 ]] && { error "Do not run as root!"; exit 1; }

close_discord

step "Checking dependencies..."

command -v git >/dev/null 2>&1 || { error "git not found. Install it first."; exit 1; }
ok "git $(git --version | awk '{print $3}')"

command -v node >/dev/null 2>&1 || { error "Node.js not found. Install LTS from https://nodejs.org"; exit 1; }
NODE_VER=$(node -e "console.log(parseInt(process.version.slice(1)))")
[[ $NODE_VER -ge 18 ]] || { error "Node.js v18+ required. You have $(node --version)"; exit 1; }
ok "Node.js $(node --version)"

if ! command -v pnpm >/dev/null 2>&1; then
    warn "pnpm not found. Installing..."
    npm install -g pnpm || { error "Failed to install pnpm"; exit 1; }
fi
ok "pnpm $(pnpm --version)"

# Clone / Update
step "Cloning / Updating repository..."
if [ -d "$INSTALL_DIR/.git" ]; then
    cd "$INSTALL_DIR"
    git fetch origin main
    git reset --hard origin/main
    ok "Repository updated."
else
    if [ -d "$INSTALL_DIR" ]; then rm -rf "$INSTALL_DIR"; fi
    git clone "$REPO_URL" "$INSTALL_DIR" || { error "Clone failed."; exit 1; }
    cd "$INSTALL_DIR"
    ok "Cloned successfully."
fi

step "Installing dependencies..."
pnpm install --frozen-lockfile || { error "Dependencies installation failed."; exit 1; }
ok "Dependencies installed."

step "Building Private MallCord..."
pnpm build || { error "Build failed."; exit 1; }
ok "Build completed."

step "Injecting into Discord..."
node "$INSTALL_DIR/scripts/runInstaller.mjs" -- --install || warn "Injection had issues (Discord may need restart)."

echo
echo -e "${GREEN}${BOLD}========================================${NC}"
echo -e "${GREEN}   Private MallCord installed successfully!${NC}"
echo -e "${GREEN}   Start Discord to load it.${NC}"
echo -e "${GREEN}========================================${NC}"
echo

exit 0
