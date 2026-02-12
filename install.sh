#!/bin/bash

NAME="ado-theme"
VERSION="1.1.0"
DESCRIPTION="A sleek and modern theme for your application - Ado Hibana Edition"

# Colors for output
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}========================================${NC}"
echo -e "${MAGENTA}Installing $NAME version $VERSION${NC}"
echo -e "${CYAN}========================================${NC}"

# Check if running on Debian-based system
if ! command -v apt &> /dev/null; then
    echo -e "${RED}Error: This script is designed for Debian-based systems (apt package manager required)${NC}"
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to install package if not already installed
install_package() {
    if ! dpkg -l | grep -q "^ii  $1 "; then
        echo -e "${CYAN}Installing $1...${NC}"
        sudo apt install -y "$1"
    else
        echo -e "${GREEN}$1 is already installed${NC}"
    fi
}

# ========================================
# PARSE ARGUMENTS
# ========================================

INSTALL_SDDM=false
INSTALL_KITTY=false
INSTALL_STARSHIP=false
INSTALL_ZSH=false
INSTALL_FASTFETCH=false
INSTALL_KATE=false
INSTALL_ROFI=false
INSTALL_ZED=false
INSTALL_FONTS=false

if [ $# -eq 0 ]; then
    # Default: Install everything
    INSTALL_SDDM=true
    INSTALL_KITTY=true
    INSTALL_STARSHIP=true
    INSTALL_ZSH=true
    INSTALL_FASTFETCH=true
    INSTALL_KATE=true
    INSTALL_ROFI=true
    INSTALL_ZED=true
    INSTALL_FONTS=true
else
    while [[ $# -gt 0 ]]; do
        case $1 in
            --sddm) INSTALL_SDDM=true ;;
            --kitty) INSTALL_KITTY=true ;;
            --starship) INSTALL_STARSHIP=true ;;
            --zsh) INSTALL_ZSH=true ;;
            --fastfetch) INSTALL_FASTFETCH=true ;;
            --kate) INSTALL_KATE=true ;;
            --rofi) INSTALL_ROFI=true ;;
            --zed) INSTALL_ZED=true ;;
            --fonts) INSTALL_FONTS=true ;;
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
                INSTALL_KWIN=true
                ;;
            --help)
                echo "Usage: ./install.sh [OPTIONS]"
                echo "Options:"
                echo "  --sddm       Install SDDM theme"
                echo "  --kitty      Install Kitty configuration"
                echo "  --starship   Install Starship prompt"
                echo "  --zsh        Install ZSH configuration"
                echo "  --fastfetch  Install Fastfetch configuration"
                echo "  --kate       Install Kate/KWrite theme"
                echo "  --rofi       Install Rofi configuration"
                echo "  --zed        Install Zed configuration"
                echo "  --fonts      Install Fonts"
                echo "  --kwin       Install KWin transparency script"
                echo "  --all        Install everything (default)"
                exit 0
                ;;
            *) echo "Unknown option: $1"; exit 1 ;;
        esac
        shift
    done
fi

# Update package list once
echo -e "${CYAN}Updating package list...${NC}"
sudo apt update

# ========================================
# INSTALL DEPENDENCIES & FONTS
# ========================================

echo -e "\n${MAGENTA}Checking common dependencies...${NC}"
install_package "curl"
install_package "git"

if [ "$INSTALL_FONTS" = true ]; then
    echo -e "\n${MAGENTA}Installing Fonts...${NC}"
    # Install fonts
    echo -e "${CYAN}Installing JetBrains Mono Nerd Font...${NC}"
    if ! fc-list | grep -qi "JetBrainsMono Nerd Font"; then
        mkdir -p ~/.local/share/fonts
        # Download to a temp dir to avoid cluttering project or home
        TEMP_DIR=$(mktemp -d)
        curl -fLo "$TEMP_DIR/JetBrainsMono.zip" https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip
        unzip -o "$TEMP_DIR/JetBrainsMono.zip" -d ~/.local/share/fonts/JetBrainsMono
        rm -rf "$TEMP_DIR"
        fc-cache -fv
        echo -e "${GREEN}JetBrains Mono Nerd Font installed${NC}"
    else
        echo -e "${GREEN}JetBrains Mono Nerd Font already installed${NC}"
    fi
fi

# ========================================
# 1. INSTALL SDDM THEME
# ========================================
if [ "$INSTALL_SDDM" = true ]; then
    echo -e "\n${MAGENTA}Installing SDDM theme...${NC}"

    install_package "sddm"
    install_package "qt6-base-dev"
    install_package "qml-module-qt5compat-graphicaleffects"

    SDDM_THEME_DIR="/usr/share/sddm/themes/$NAME"

    if [ -d "$SDDM_THEME_DIR" ]; then
        sudo rm -rf "$SDDM_THEME_DIR"
        echo -e "${CYAN}Removed existing SDDM theme directory${NC}"
    fi

    echo -e "${CYAN}Copying SDDM theme files to $SDDM_THEME_DIR${NC}"
    sudo cp -r ./ado-sddm "$SDDM_THEME_DIR"

    # Configure SDDM to use the theme
    SDDM_CONF="/etc/sddm.conf"
    SDDM_CONF_D="/etc/sddm.conf.d"

    if [ ! -f "$SDDM_CONF" ] && [ ! -d "$SDDM_CONF_D" ]; then
        echo -e "${CYAN}Creating SDDM configuration...${NC}"
        sudo mkdir -p "$SDDM_CONF_D"
    fi

    echo -e "${CYAN}Setting SDDM theme to $NAME${NC}"
    # Check if directory exists before writing, if not create file in /etc/sddm.conf.d/ or append to /etc/sddm.conf
    # The previous logic assumed /etc/sddm.conf.d exists or was created.
    if [ -d "$SDDM_CONF_D" ]; then
        echo "[Theme]" | sudo tee "$SDDM_CONF_D/ado-theme.conf" > /dev/null
        echo "Current=$NAME" | sudo tee -a "$SDDM_CONF_D/ado-theme.conf" > /dev/null
    else
        # Fallback if conf.d doesn't exist (though we tried to create it)
        echo "[Theme]" | sudo tee -a "$SDDM_CONF" > /dev/null
        echo "Current=$NAME" | sudo tee -a "$SDDM_CONF" > /dev/null
    fi

    echo -e "${GREEN}SDDM theme installed and configured${NC}"
fi

# ========================================
# 2. INSTALL KITTY CONFIGURATION
# ========================================
if [ "$INSTALL_KITTY" = true ]; then
    echo -e "\n${MAGENTA}Installing Kitty terminal configuration...${NC}"

    install_package "kitty"

    KITTY_CONFIG_DIR="$HOME/.config/kitty"
    mkdir -p "$KITTY_CONFIG_DIR"

    if [ -f "$KITTY_CONFIG_DIR/kitty.conf" ]; then
        cp "$KITTY_CONFIG_DIR/kitty.conf" "$KITTY_CONFIG_DIR/kitty.conf.backup.$(date +%Y%m%d_%H%M%S)"
        echo -e "${CYAN}Backed up existing kitty.conf${NC}"
    fi

    # Path changed from terminalCustomization to terminal
    cp ./terminal/kitty/kitty.conf "$KITTY_CONFIG_DIR/kitty.conf"
    echo -e "${GREEN}Kitty configuration installed${NC}"
fi

# ========================================
# 3. INSTALL STARSHIP CONFIGURATION
# ========================================
if [ "$INSTALL_STARSHIP" = true ]; then
    echo -e "\n${MAGENTA}Installing Starship prompt configuration...${NC}"

    # Install Starship prompt binary
    if ! command_exists starship; then
        echo -e "${CYAN}Installing Starship prompt...${NC}"
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    else
        echo -e "${GREEN}Starship is already installed${NC}"
    fi

    STARSHIP_CONFIG_DIR="$HOME/.config"
    mkdir -p "$STARSHIP_CONFIG_DIR"

    if [ -f "$STARSHIP_CONFIG_DIR/starship.toml" ]; then
        cp "$STARSHIP_CONFIG_DIR/starship.toml" "$STARSHIP_CONFIG_DIR/starship.toml.backup.$(date +%Y%m%d_%H%M%S)"
        echo -e "${CYAN}Backed up existing starship.toml${NC}"
    fi

    # Path changed from terminalCustomization to terminal
    cp ./terminal/starship/starship.toml "$STARSHIP_CONFIG_DIR/starship.toml"
    echo -e "${GREEN}Starship configuration installed${NC}"
fi

# ========================================
# 4. INSTALL ZSH CONFIGURATION
# ========================================
if [ "$INSTALL_ZSH" = true ]; then
    echo -e "\n${MAGENTA}Installing ZSH configuration...${NC}"

    install_package "zsh"

    # Install Oh My Zsh if not present
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo -e "${CYAN}Installing Oh My Zsh...${NC}"
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        echo -e "${GREEN}Oh My Zsh already installed${NC}"
    fi

    # Configure ZSH to use starship (only if starship is installed or selected)
    ZSHRC="$HOME/.zshrc"
    # if [ -f "$ZSHRC" ]; then
    #     # Backup existing .zshrc
    #     cp "$ZSHRC" "$ZSHRC.backup.$(date +%Y%m%d_%H%M%S)"
    #     echo -e "${CYAN}Backed up existing .zshrc${NC}"
    # fi

    cp "./terminal/zsh/.zshrc" "$ZSHRC"

    # Add starship initialization to .zshrc if not present
    if ! grep -q "starship init zsh" "$ZSHRC" 2>/dev/null; then
        echo -e "\n# Initialize Starship prompt" >> "$ZSHRC"
        echo 'eval "$(starship init zsh)"' >> "$ZSHRC"
        echo -e "${GREEN}Added Starship to .zshrc${NC}"
    fi

    # Set ZSH as default shell if not already
    if [ "$SHELL" != "$(which zsh)" ]; then
        echo -e "${CYAN}Setting ZSH as default shell...${NC}"
        chsh -s "$(which zsh)"
        echo -e "${GREEN}ZSH set as default shell (restart required)${NC}"
    fi
fi

# ========================================
# 5. INSTALL FASTFETCH CONFIGURATION
# ========================================
if [ "$INSTALL_FASTFETCH" = true ]; then
    echo -e "\n${MAGENTA}Installing Fastfetch configuration...${NC}"

    install_package "fastfetch"

    ZSHRC="$HOME/.zshrc"

    # Add fastfetch to .zshrc if not present
    if [ -f "$ZSHRC" ]; then
        if ! grep -q "fastfetch" "$ZSHRC" 2>/dev/null; then
            echo -e "\n# Run fastfetch on terminal start" >> "$ZSHRC"
            echo 'if command -v fastfetch &> /dev/null; then' >> "$ZSHRC"
            echo '    fastfetch --config ~/.config/fastfetch/ado.jsonc' >> "$ZSHRC"
            echo 'fi' >> "$ZSHRC"
            echo -e "${GREEN}Added Fastfetch to .zshrc${NC}"
        fi
    fi

    # Install Fastfetch configuration
    FASTFETCH_CONFIG_DIR="$HOME/.config/fastfetch"
    mkdir -p "$FASTFETCH_CONFIG_DIR"

    # Path changed to terminal/fastfetch
    cp ./terminal/fastfetch/ado.jsonc "$FASTFETCH_CONFIG_DIR/ado.jsonc"
    cp ./terminal/fastfetch/ado.png "$FASTFETCH_CONFIG_DIR/ado.png"
    echo -e "${GREEN}Fastfetch configuration installed${NC}"
fi

# ========================================
# 6. INSTALL KATE/KWRITE COLOR SCHEME
# ========================================
if [ "$INSTALL_KATE" = true ]; then
    echo -e "\n${MAGENTA}Installing Kate/KWrite color scheme...${NC}"

    KATE_COLOR_DIR="$HOME/.local/share/org.kde.syntax-highlighting/themes"
    mkdir -p "$KATE_COLOR_DIR"

    if [ -f "$KATE_COLOR_DIR/Ado-Hibana.theme" ]; then
        cp "$KATE_COLOR_DIR/Ado-Hibana.theme" "$KATE_COLOR_DIR/Ado-Hibana.theme.backup.$(date +%Y%m%d_%H%M%S)"
        echo -e "${CYAN}Backed up existing Ado-Hibana.theme${NC}"
    fi

    cp ./kate/Ado-Hibana.theme "$KATE_COLOR_DIR/Ado-Hibana.theme"
    echo -e "${GREEN}Kate/KWrite color scheme installed${NC}"
    echo -e "${CYAN}To activate: Open Kate/KWrite → Settings → Configure Kate → Editor Component → Colors & Fonts → Select 'Ado Hibana'${NC}"
fi

# ========================================
# 7. INSTALL ROFI CONFIGURATION
# ========================================
if [ "$INSTALL_ROFI" = true ]; then
    echo -e "\n${MAGENTA}Installing Rofi configuration...${NC}"

    install_package "rofi"

    ROFI_CONFIG_DIR="$HOME/.config/rofi"
    mkdir -p "$ROFI_CONFIG_DIR"

    if [ -f "$ROFI_CONFIG_DIR/config.rasi" ]; then
        cp "$ROFI_CONFIG_DIR/config.rasi" "$ROFI_CONFIG_DIR/config.rasi.backup.$(date +%Y%m%d_%H%M%S)"
        echo -e "${CYAN}Backed up existing config.rasi${NC}"
    fi

    cp ./rofi/config.rasi "$ROFI_CONFIG_DIR/config.rasi"
    cp ./rofi/ado.rasi "$ROFI_CONFIG_DIR/ado.rasi"
    echo -e "${GREEN}Rofi configuration installed${NC}"
fi

# ========================================
# 8. INSTALL ZED CONFIGURATION
# ========================================
if [ "$INSTALL_ZED" = true ]; then
    echo -e "\n${MAGENTA}Installing Zed configuration...${NC}"

    ZED_CONFIG_DIR="$HOME/.config/zed"
    ZED_THEME_DIR="$ZED_CONFIG_DIR/themes"
    mkdir -p "$ZED_THEME_DIR"

    # Backup existing settings
    if [ -f "$ZED_CONFIG_DIR/settings.json" ]; then
        cp "$ZED_CONFIG_DIR/settings.json" "$ZED_CONFIG_DIR/settings.json.backup.$(date +%Y%m%d_%H%M%S)"
        echo -e "${CYAN}Backed up existing Zed settings.json${NC}"
    fi

    # Install Themes
    cp ./zed/Ado-Hibana.json "$ZED_THEME_DIR/Ado-Hibana.json"
    echo -e "${GREEN}Zed themes installed:${NC}"
    echo -e "${CYAN}  • Ado Hibana (Original) - High contrast, vibrant colors${NC}"
    echo -e "${CYAN}  • Ado Hibana Soft (Recommended) - Eye-friendly for long sessions${NC}"

    # Install Settings
    cp ./zed/settings.json "$ZED_CONFIG_DIR/settings.json"
    echo -e "${GREEN}Zed settings installed (using Ado Hibana Soft theme)${NC}"
    echo -e "${CYAN}To switch themes: Cmd/Ctrl+Shift+P → 'Select Theme'${NC}"
fi

# ========================================
# 9. INSTALL KWIN SCRIPT
# ========================================
if [ "$INSTALL_KWIN" = true ]; then
    echo -e "\n${MAGENTA}Installing KWin Transparency Script...${NC}"

    if ! command_exists kpackagetool6; then
        echo -e "${RED}Error: kpackagetool6 not found. Is KDE Plasma 6 installed?${NC}"
    else
        # Install or Upgrade script
        if kpackagetool6 --type KWin/Script --list | grep -q "ado-monitor-transparency"; then
            echo -e "${CYAN}Upgrading existing script...${NC}"
            kpackagetool6 --type KWin/Script --upgrade ./kwin/
        else
            echo -e "${CYAN}Installing new script...${NC}"
            kpackagetool6 --type KWin/Script --install ./kwin/
        fi

        # Enable the script
        echo -e "${CYAN}Enabling script...${NC}"
        if command_exists kwriteconfig6; then
             kwriteconfig6 --file kwinrc --group Plugins --key ado-monitor-transparencyEnabled true
             echo -e "${GREEN}Script enabled in kwinrc${NC}"

             # Reload KWin if possible (DBus)
             if command_exists qdbus6; then
                 qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1
                 echo -e "${GREEN}Requested KWin reconfigure${NC}"
             fi
        else
             echo -e "${CYAN}Manually enable the script in System Settings -> Window Management -> KWin Scripts${NC}"
        fi

        echo -e "${GREEN}KWin transparency script installed${NC}"
    fi
fi

# ========================================
# INSTALLATION COMPLETE
# ========================================
echo -e "\n${CYAN}========================================${NC}"
echo -e "${GREEN}✓ Installation Tasks Completed!${NC}"
echo -e "${CYAN}========================================${NC}"

echo -e "\n${MAGENTA}Installed components:${NC}"
echo -e "  ${CYAN}✓${NC} SDDM Theme (${NAME})"
echo -e "  ${CYAN}✓${NC} Kitty Terminal Configuration"
echo -e "  ${CYAN}✓${NC} Starship Prompt"
echo -e "  ${CYAN}✓${NC} ZSH Configuration"
echo -e "  ${CYAN}✓${NC} Fastfetch Configuration"
echo -e "  ${CYAN}✓${NC} Kate/KWrite Color Scheme"
echo -e "  ${CYAN}✓${NC} Rofi Launcher Theme"
echo -e "  ${CYAN}✓${NC} Zed Editor Configuration"
echo -e "  ${CYAN}✓${NC} JetBrainsMono Nerd Font"
echo -e "  ${CYAN}✓${NC} KWin Transparency Script"

echo -e "\n${MAGENTA}Next steps:${NC}"
echo -e "  1. ${CYAN}Log out and back in${NC} to see the new SDDM theme"
echo -e "  2. ${CYAN}Restart your terminal${NC} or run: ${GREEN}source ~/.zshrc${NC}"
echo -e "  3. ${CYAN}Launch Rofi${NC} with: ${GREEN}rofi -show drun${NC}"
echo -e "  4. ${CYAN}Open Kitty${NC} to see the new terminal theme"
echo -e "  5. ${CYAN}Open Kate/KWrite${NC} and select the 'Ado Hibana' theme in settings"
echo -e "  6. ${CYAN}Open Zed${NC} to see the eye-friendly 'Ado Hibana Soft' theme"
echo -e "  7. ${CYAN}Verify Transparency${NC}: Open windows on your second monitor to see the dimming effect"

echo -e "\n${MAGENTA}Configuration files:${NC}"
echo -e "  SDDM:      ${CYAN}$SDDM_THEME_DIR${NC}"
echo -e "  Kitty:     ${CYAN}$KITTY_CONFIG_DIR/kitty.conf${NC}"
echo -e "  Starship:  ${CYAN}$STARSHIP_CONFIG_DIR/starship.toml${NC}"
echo -e "  Fastfetch: ${CYAN}$FASTFETCH_CONFIG_DIR/ado.jsonc${NC}"
echo -e "  Kate:      ${CYAN}$KATE_COLOR_DIR/Ado-Hibana.theme${NC}"
echo -e "  Rofi:      ${CYAN}$ROFI_CONFIG_DIR/${NC}"
echo -e "  Zed:       ${CYAN}$ZED_CONFIG_DIR/settings.json${NC}"
echo -e "  ZSH:       ${CYAN}$ZSHRC${NC}"
echo -e "  KWin:      ${CYAN}~/.local/share/kwin/scripts/ado-monitor-transparency${NC}"

echo -e "\n${GREEN}Enjoy your new Ado Hibana theme! 🔥${NC}\n"
