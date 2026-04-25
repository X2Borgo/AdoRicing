#!/bin/bash

set -e

NAME="ado-theme"
VERSION="1.3.0"
DESCRIPTION="Ado Hibana theme suite for Debian Trixie / Hyprland"

CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${CYAN}========================================${NC}"
echo -e "${MAGENTA}Installing $NAME version $VERSION${NC}"
echo -e "${CYAN}========================================${NC}"

if ! command -v apt >/dev/null 2>&1; then
    echo -e "${RED}Error: this installer targets Debian-based systems with apt${NC}"
    exit 1
fi

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

install_package() {
    if ! dpkg -l | grep -q "^ii  $1 "; then
        echo -e "${CYAN}Installing $1...${NC}"
        sudo apt install -y "$1"
    else
        echo -e "${GREEN}$1 is already installed${NC}"
    fi
}

backup_file() {
    local target="$1"
    if [ -f "$target" ]; then
        cp "$target" "$target.backup.$(date +%Y%m%d_%H%M%S)"
        echo -e "${CYAN}Backed up $target${NC}"
    fi
}

append_component() {
    INSTALLED_COMPONENTS+=("$1")
}

INSTALL_SDDM=false
INSTALL_KITTY=false
INSTALL_STARSHIP=false
INSTALL_ZSH=false
INSTALL_FASTFETCH=false
INSTALL_KATE=false
INSTALL_ROFI=false
INSTALL_ZED=false
INSTALL_FONTS=false
INSTALL_CAELESTIA_SHELL=false
INSTALL_QUICKSHELL=false
INSTALL_HYPR_CONFIG=false
INSTALL_KWIN=false

if [ $# -eq 0 ]; then
    INSTALL_HYPR_CONFIG=true
    INSTALL_KITTY=true
    INSTALL_STARSHIP=true
    INSTALL_ZSH=true
    INSTALL_FASTFETCH=true
    INSTALL_ROFI=true
    INSTALL_ZED=true
    INSTALL_FONTS=true
    INSTALL_CAELESTIA_SHELL=true
    INSTALL_QUICKSHELL=true
else
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --sddm) INSTALL_SDDM=true ;;
            --kitty) INSTALL_KITTY=true ;;
            --starship) INSTALL_STARSHIP=true ;;
            --zsh) INSTALL_ZSH=true ;;
            --fastfetch) INSTALL_FASTFETCH=true ;;
            --kate) INSTALL_KATE=true ;;
            --rofi) INSTALL_ROFI=true ;;
            --zed) INSTALL_ZED=true ;;
            --fonts) INSTALL_FONTS=true ;;
            --caelestia-shell) INSTALL_CAELESTIA_SHELL=true ;;
            --quickshell) INSTALL_QUICKSHELL=true ;;
            --hypr|--hypr-config) INSTALL_HYPR_CONFIG=true ;;
            --kwin) INSTALL_KWIN=true ;;
            --all)
                INSTALL_SDDM=true
                INSTALL_KITTY=true
                INSTALL_STARSHIP=true
                INSTALL_ZSH=true
                INSTALL_FASTFETCH=true
                INSTALL_KATE=true
                INSTALL_ROFI=true
                INSTALL_ZED=true
                INSTALL_FONTS=true
                INSTALL_CAELESTIA_SHELL=true
                INSTALL_QUICKSHELL=true
                INSTALL_HYPR_CONFIG=true
                INSTALL_KWIN=true
                ;;
            --hyprland)
                INSTALL_HYPR_CONFIG=true
                INSTALL_KITTY=true
                INSTALL_STARSHIP=true
                INSTALL_ZSH=true
                INSTALL_FASTFETCH=true
                INSTALL_ROFI=true
                INSTALL_ZED=true
                INSTALL_FONTS=true
                INSTALL_CAELESTIA_SHELL=true
                INSTALL_QUICKSHELL=true
                ;;
            --help)
                echo "Usage: ./install.sh [OPTIONS]"
                echo ""
                echo "Default with no options installs the Hyprland-focused set:"
                echo "  hypr config, local caelestia shell link, kitty, starship, zsh, fastfetch, rofi, zed, fonts, quickshell"
                echo ""
                echo "Options:"
                echo "  --hyprland    Install the Hyprland-focused set"
                echo "  --hypr        Alias for --hypr-config"
                echo "  --hypr-config Install Hyprland config folder (~/.config/hypr)"
                echo "  --sddm        Install the optional SDDM login theme"
                echo "  --kitty       Install Kitty configuration"
                echo "  --starship    Install Starship prompt"
                echo "  --zsh         Install ZSH configuration"
                echo "  --fastfetch   Install Fastfetch configuration"
                echo "  --kate        Install Kate/KWrite theme"
                echo "  --rofi        Install Rofi configuration"
                echo "  --zed         Install Zed themes and settings"
                echo "  --fonts       Install JetBrainsMono Nerd Font"
                echo "  --caelestia-shell Link local shell/ repo to ~/.config/quickshell/caelestia"
                echo "                    (does not build/install Caelestia QML plugins)"
                echo "  --quickshell  Install Quickshell panel config"
                echo "  --kwin        Install legacy Plasma-only KWin script"
                echo "  --all         Install everything, including legacy Plasma pieces"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
        shift
    done
fi

echo -e "${CYAN}Updating package list...${NC}"
sudo apt update

echo -e "\n${MAGENTA}Checking common dependencies...${NC}"
install_package "curl"
install_package "git"
install_package "unzip"

INSTALLED_COMPONENTS=()

if [ "$INSTALL_HYPR_CONFIG" = true ]; then
    echo -e "\n${MAGENTA}Installing Hyprland config...${NC}"

    HYPR_CONFIG_DIR="$HOME/.config/hypr"
    HYPR_BACKUP_DIR="$HOME/.config/hypr.backup.$(date +%Y%m%d_%H%M%S)"

    if [ -d "$HYPR_CONFIG_DIR" ]; then
        cp -a "$HYPR_CONFIG_DIR" "$HYPR_BACKUP_DIR"
        echo -e "${CYAN}Backed up existing Hyprland config to $HYPR_BACKUP_DIR${NC}"
    fi

    mkdir -p "$HYPR_CONFIG_DIR"
    cp -a "$SCRIPT_DIR/hypr/." "$HYPR_CONFIG_DIR/"

    if [ -f "$HYPR_CONFIG_DIR/initial-boot.sh" ]; then
        chmod +x "$HYPR_CONFIG_DIR/initial-boot.sh"
    fi
    if [ -d "$HYPR_CONFIG_DIR/scripts" ]; then
        find "$HYPR_CONFIG_DIR/scripts" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} +
    fi
    if [ -d "$HYPR_CONFIG_DIR/UserScripts" ]; then
        find "$HYPR_CONFIG_DIR/UserScripts" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} +
    fi

    if ! command_exists caelestia && ! command_exists qs && ! command_exists quickshell; then
        echo -e "${YELLOW}Warning: no shell launcher found (caelestia/qs/quickshell). Install Caelestia shell or Quickshell.${NC}"
    fi

    echo -e "${GREEN}Hyprland config installed${NC}"
    append_component "Hyprland config"
fi

if [ "$INSTALL_FONTS" = true ]; then
    echo -e "\n${MAGENTA}Installing fonts...${NC}"
    if ! fc-list | grep -qi "JetBrainsMono Nerd Font"; then
        mkdir -p "$HOME/.local/share/fonts"
        TEMP_DIR=$(mktemp -d)
        curl -fLo "$TEMP_DIR/JetBrainsMono.zip" \
            https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip
        unzip -o "$TEMP_DIR/JetBrainsMono.zip" -d "$HOME/.local/share/fonts/JetBrainsMono"
        rm -rf "$TEMP_DIR"
        fc-cache -fv
        echo -e "${GREEN}JetBrainsMono Nerd Font installed${NC}"
    else
        echo -e "${GREEN}JetBrainsMono Nerd Font already installed${NC}"
    fi
    append_component "Fonts"
fi

if [ "$INSTALL_SDDM" = true ]; then
    echo -e "\n${MAGENTA}Installing optional SDDM theme...${NC}"

    install_package "sddm"
    install_package "qt6-base-dev"
    install_package "qml-module-qt5compat-graphicaleffects"

    SDDM_THEME_DIR="/usr/share/sddm/themes/$NAME"
    SDDM_CONF_D="/etc/sddm.conf.d"

    if [ -d "$SDDM_THEME_DIR" ]; then
        sudo rm -rf "$SDDM_THEME_DIR"
        echo -e "${CYAN}Removed existing SDDM theme directory${NC}"
    fi

    sudo cp -r "$SCRIPT_DIR/ado-sddm" "$SDDM_THEME_DIR"

    sudo mkdir -p "$SDDM_CONF_D"
    {
        echo "[Theme]"
        echo "Current=$NAME"
    } | sudo tee "$SDDM_CONF_D/ado-theme.conf" >/dev/null

    echo -e "${GREEN}SDDM theme installed and configured${NC}"
    append_component "SDDM theme"
fi

if [ "$INSTALL_KITTY" = true ]; then
    echo -e "\n${MAGENTA}Installing Kitty configuration...${NC}"
    install_package "kitty"

    KITTY_CONFIG_DIR="$HOME/.config/kitty"
    mkdir -p "$KITTY_CONFIG_DIR"
    backup_file "$KITTY_CONFIG_DIR/kitty.conf"
    cp "$SCRIPT_DIR/terminal/kitty/kitty.conf" "$KITTY_CONFIG_DIR/kitty.conf"

    echo -e "${GREEN}Kitty configuration installed${NC}"
    append_component "Kitty"
fi

if [ "$INSTALL_STARSHIP" = true ]; then
    echo -e "\n${MAGENTA}Installing Starship configuration...${NC}"

    if ! command_exists starship; then
        echo -e "${CYAN}Installing Starship prompt...${NC}"
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    else
        echo -e "${GREEN}Starship is already installed${NC}"
    fi

    STARSHIP_CONFIG_DIR="$HOME/.config"
    mkdir -p "$STARSHIP_CONFIG_DIR"
    backup_file "$STARSHIP_CONFIG_DIR/starship.toml"
    cp "$SCRIPT_DIR/terminal/starship/starship.toml" "$STARSHIP_CONFIG_DIR/starship.toml"

    echo -e "${GREEN}Starship configuration installed${NC}"
    append_component "Starship"
fi

if [ "$INSTALL_ZSH" = true ]; then
    echo -e "\n${MAGENTA}Installing ZSH configuration...${NC}"
    install_package "zsh"

    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo -e "${CYAN}Installing Oh My Zsh...${NC}"
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        echo -e "${GREEN}Oh My Zsh already installed${NC}"
    fi

    ZSHRC="$HOME/.zshrc"
    backup_file "$ZSHRC"
    cp "$SCRIPT_DIR/terminal/zsh/.zshrc" "$ZSHRC"

    if ! grep -q "starship init zsh" "$ZSHRC" 2>/dev/null; then
        echo "" >> "$ZSHRC"
        echo "# Initialize Starship prompt" >> "$ZSHRC"
        echo 'eval "$(starship init zsh)"' >> "$ZSHRC"
    fi

    if [ "$SHELL" != "$(command -v zsh)" ]; then
        echo -e "${CYAN}Setting ZSH as default shell...${NC}"
        chsh -s "$(command -v zsh)"
        echo -e "${GREEN}ZSH set as default shell${NC}"
    fi

    echo -e "${GREEN}ZSH configuration installed${NC}"
    append_component "ZSH"
fi

if [ "$INSTALL_FASTFETCH" = true ]; then
    echo -e "\n${MAGENTA}Installing Fastfetch configuration...${NC}"
    install_package "fastfetch"

    FASTFETCH_CONFIG_DIR="$HOME/.config/fastfetch"
    mkdir -p "$FASTFETCH_CONFIG_DIR"
    cp "$SCRIPT_DIR/terminal/fastfetch/ado.jsonc" "$FASTFETCH_CONFIG_DIR/ado.jsonc"
    cp "$SCRIPT_DIR/terminal/fastfetch/ado.png" "$FASTFETCH_CONFIG_DIR/ado.png"

    ZSHRC="${ZSHRC:-$HOME/.zshrc}"
    if [ -f "$ZSHRC" ] && ! grep -q "fastfetch --config ~/.config/fastfetch/ado.jsonc" "$ZSHRC" 2>/dev/null; then
        echo "" >> "$ZSHRC"
        echo "# Run fastfetch on terminal start" >> "$ZSHRC"
        echo 'if command -v fastfetch >/dev/null 2>&1; then' >> "$ZSHRC"
        echo '    fastfetch --config ~/.config/fastfetch/ado.jsonc' >> "$ZSHRC"
        echo 'fi' >> "$ZSHRC"
    fi

    echo -e "${GREEN}Fastfetch configuration installed${NC}"
    append_component "Fastfetch"
fi

if [ "$INSTALL_KATE" = true ]; then
    echo -e "\n${MAGENTA}Installing Kate/KWrite theme...${NC}"

    KATE_COLOR_DIR="$HOME/.local/share/org.kde.syntax-highlighting/themes"
    mkdir -p "$KATE_COLOR_DIR"
    backup_file "$KATE_COLOR_DIR/Ado-Hibana.theme"
    cp "$SCRIPT_DIR/kate/Ado-Hibana.theme" "$KATE_COLOR_DIR/Ado-Hibana.theme"

    echo -e "${GREEN}Kate/KWrite theme installed${NC}"
    append_component "Kate/KWrite"
fi

if [ "$INSTALL_ROFI" = true ]; then
    echo -e "\n${MAGENTA}Installing Rofi configuration...${NC}"
    install_package "rofi"

    ROFI_CONFIG_DIR="$HOME/.config/rofi"
    mkdir -p "$ROFI_CONFIG_DIR"
    backup_file "$ROFI_CONFIG_DIR/config.rasi"
    cp "$SCRIPT_DIR/rofi/config.rasi" "$ROFI_CONFIG_DIR/config.rasi"
    cp "$SCRIPT_DIR/rofi/ado.rasi" "$ROFI_CONFIG_DIR/ado.rasi"

    echo -e "${GREEN}Rofi configuration installed${NC}"
    append_component "Rofi"
fi

if [ "$INSTALL_ZED" = true ]; then
    echo -e "\n${MAGENTA}Installing Zed configuration...${NC}"

    ZED_CONFIG_DIR="$HOME/.config/zed"
    ZED_THEME_DIR="$ZED_CONFIG_DIR/themes"
    mkdir -p "$ZED_THEME_DIR"
    backup_file "$ZED_CONFIG_DIR/settings.json"
    cp "$SCRIPT_DIR/zed/Ado-Hibana.json" "$ZED_THEME_DIR/Ado-Hibana.json"
    cp "$SCRIPT_DIR/zed/settings.json" "$ZED_CONFIG_DIR/settings.json"

    echo -e "${GREEN}Zed themes and settings installed${NC}"
    append_component "Zed"
fi

if [ "$INSTALL_CAELESTIA_SHELL" = true ]; then
    echo -e "\n${MAGENTA}Configuring local Caelestia shell repo...${NC}"

    if [ ! -f "$SCRIPT_DIR/shell/shell.qml" ]; then
        echo -e "${YELLOW}Local shell repo not found at $SCRIPT_DIR/shell. Skipping Caelestia setup.${NC}"
    else
        CAELESTIA_CONFIG_ROOT="$HOME/.config/quickshell"
        CAELESTIA_DEST="$CAELESTIA_CONFIG_ROOT/caelestia"
        mkdir -p "$CAELESTIA_CONFIG_ROOT"

        if [ -e "$CAELESTIA_DEST" ] && [ ! -L "$CAELESTIA_DEST" ]; then
            mv "$CAELESTIA_DEST" "$CAELESTIA_DEST.backup.$(date +%Y%m%d_%H%M%S)"
            echo -e "${CYAN}Backed up existing $CAELESTIA_DEST${NC}"
        fi

        ln -sfn "$SCRIPT_DIR/shell" "$CAELESTIA_DEST"
        echo -e "${GREEN}Linked $CAELESTIA_DEST -> $SCRIPT_DIR/shell${NC}"
        echo -e "${YELLOW}Note: this only links the shell sources. The compiled Caelestia/qs.utils QML modules must already be installed for it to render.${NC}"

        if ! command_exists qs && ! command_exists caelestia; then
            echo -e "${YELLOW}Warning: install quickshell/qs or caelestia CLI to launch Caelestia shell.${NC}"
        fi

        append_component "Caelestia shell (local repo link)"
    fi
fi

if [ "$INSTALL_QUICKSHELL" = true ]; then
    echo -e "\n${MAGENTA}Installing Quickshell panel config...${NC}"

    QUICKSHELL_CONFIG_DIR="$HOME/.config/quickshell/AdoRicing"
    mkdir -p "$QUICKSHELL_CONFIG_DIR"
    backup_file "$QUICKSHELL_CONFIG_DIR/main.qml"
    cp "$SCRIPT_DIR/quickshell/main.qml" "$QUICKSHELL_CONFIG_DIR/main.qml"
    cp "$SCRIPT_DIR/useful_images/Ado-Rose.svg" "$QUICKSHELL_CONFIG_DIR/Ado-Rose.svg"

    echo -e "${GREEN}Quickshell config installed${NC}"
    echo -e "${YELLOW}Make sure the quickshell binary itself is installed separately${NC}"
    append_component "Quickshell panel"
fi

if [ "$INSTALL_KWIN" = true ]; then
    echo -e "\n${MAGENTA}Installing legacy KWin script...${NC}"
    echo -e "${YELLOW}This component only applies to KDE Plasma and is not used on Hyprland${NC}"
    "$SCRIPT_DIR/kwin/install.sh"
    append_component "Legacy KWin script"
fi

echo -e "\n${CYAN}========================================${NC}"
echo -e "${GREEN}✓ Installation tasks completed${NC}"
echo -e "${CYAN}========================================${NC}"

if [ ${#INSTALLED_COMPONENTS[@]} -gt 0 ]; then
    echo -e "\n${MAGENTA}Installed components:${NC}"
    for component in "${INSTALLED_COMPONENTS[@]}"; do
        echo -e "  ${CYAN}•${NC} $component"
    done
else
    echo -e "\n${YELLOW}No components were selected.${NC}"
fi

echo -e "\n${MAGENTA}Next steps:${NC}"
echo -e "  1. ${CYAN}Restart your terminal${NC} or run ${GREEN}source ~/.zshrc${NC}"
echo -e "  2. ${CYAN}Launch Rofi${NC} with ${GREEN}rofi -show drun${NC}"
echo -e "  3. ${CYAN}Open Kitty${NC} to verify the terminal theme"
echo -e "  4. ${CYAN}Open Zed${NC} to verify the editor theme"
echo -e "  5. ${CYAN}Reload Hyprland${NC} with ${GREEN}hyprctl reload${NC}"
echo -e "  6. ${CYAN}If linked successfully, Caelestia shell is now used from${NC} ${GREEN}~/Desktop/AdoRicing/shell${NC}"
echo -e "  7. ${CYAN}If using SDDM${NC}, log out and back in to verify the greeter theme"

echo -e "\n${GREEN}AdoRicing is now aligned with a Hyprland-first setup.${NC}\n"
