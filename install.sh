#!/bin/bash

# =============================================================================
# Arch Linux Rice Installation Script (Fixed Version)
# =============================================================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Starting installation...${NC}"

# 1. Check for yay
if ! command -v yay &> /dev/null; then
    echo -e "${RED}Error: yay is not installed.${NC}"
    exit 1
fi

if ! command -v flatpak &> /dev/null; then
    echo -e "${RED}Error: flatpak is not installed.${NC}"
    exit 1
fi

# 2. Install System Dependencies
if [ -f "pkglist.txt" ]; then
    echo -e "${BLUE}Installing packages from pkglist.txt...${NC}"
    yay -S --needed --noconfirm $(cat pkglist.txt)
else
    echo -e "${RED}Warning: pkglist.txt not found! Skipping system pkgs.${NC}"
fi

if [ -f "flatpak.txt" ]; then
    echo -e "${BLUE}Installing packages from flatpak.txt using flatpak...${NC}"
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    cat flatpak.txt | xargs flatpak install -y
else
    echo -e "${RED}Error: flatpak.txt not found!${NC}"
    exit 1
fi

echo -e "${BLUE}Installing Pywal backend dependencies...${NC}"
pip install haishoku colorthief --break-system-packages 2>/dev/null || pip install haishoku colorthief

backup_config() {
    if [ -d "$1" ]; then
        BACKUP_NAME="${1}_backup_$(date +%Y%m%d_%H%M%S)"
        echo -e "${BLUE}Backing up existing $(basename $1) to $(basename $BACKUP_NAME)${NC}"
        mv "$1" "$BACKUP_NAME"
    fi
}

backup_config ~/.config/mako
backup_config ~/.config/fastfetch
backup_config ~/.config/kitty
backup_config ~/.config/systemd
backup_config ~/.config/wallpapers
backup_config ~/.config/hypr
backup_config ~/.config/waybar
backup_config ~/.config/wofi

# 3. Create structure and Copy Configs
echo -e "${BLUE}Deploying configuration files...${NC}"
mkdir -p ~/.config
cp -rv .config ~/

PRIMARY_MONITOR=$(hyprctl monitors | grep "Monitor" | awk '{print $2}' | head -n 1)

if [ -n "$PRIMARY_MONITOR" ]; then
    echo -e "${BLUE}Detected monitor: $PRIMARY_MONITOR. Updating configs...${NC}"
    find "$HOME/.config" -type f -exec sed -i "s/DP-1/$PRIMARY_MONITOR/g" {} +
    find "$HOME/.config" -type f -exec sed -i "s/eDP-1/$PRIMARY_MONITOR/g" {} +
fi

cp .face.icon ~/
cp change-avatar.sh ~/

# 4. Path Replacement Logic
# This handles the replacement in the newly copied ~/.config files
SEARCH="/home/nekorosys"
REPLACE="/home/$USER"

echo -e "${BLUE}Replacing $SEARCH with $REPLACE in config files...${NC}"
find "$HOME/.config" -type f -exec grep -l "$SEARCH" {} + 2>/dev/null | xargs -r sed -i "s|$SEARCH|$REPLACE|g" 2>/dev/null

# 6. Permissions and Services
echo -e "${BLUE}Setting script permissions...${NC}"
find ~/.config/hypr/scripts -name "*.sh" -exec chmod +x {} + 2>/dev/null
echo -e "${BLUE}Enabling waybar...${NC}"
sudo systemctl enable ~/.config/systemd/user/waybar.service

echo -e "${GREEN}Installation complete! Please restart your session.${NC}"
