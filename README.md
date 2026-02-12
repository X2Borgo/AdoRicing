# AdoRicing - Ado Hibana Theme Suite

A comprehensive theming system for Debian Trixie/KDE Plasma 6 Wayland, inspired by Ado's "Hibana" World Tour 2025. This suite provides a cohesive cyberpunk aesthetic across your entire desktop environment with an emphasis on both visual appeal and usability.

![Version](https://img.shields.io/badge/version-1.1.0-blue)
![Platform](https://img.shields.io/badge/platform-Debian%20Trixie-red)
![DE](https://img.shields.io/badge/DE-KDE%20Plasma%206-blue)
![Display](https://img.shields.io/badge/display-Wayland-green)

## 🎨 What's Included

### 🔐 SDDM Login Theme
- Custom QML-based theme with cyberpunk aesthetics
- Animated entrance with staggered fade-in effects
- Auto-focus password field for instant login
- Auto-select last user on startup
- Glowing password field with pulsing animations
- System buttons (shutdown, reboot, hibernate, suspend)
- Session selector integration
- Clock and date display
- Blur effects and custom backgrounds

### 💻 Terminal Customization
- **Kitty Terminal** - Complete Ado Hibana color scheme with 95% transparency
- **Starship Prompt** - Segmented pill design with git integration
- **ZSH Configuration** - Oh My Zsh with Starship initialization
- **Fastfetch** - Custom system info with Ado branding

### 🎨 Editor Themes
- **Kate/KWrite** - Complete syntax highlighting for 40+ languages
- **Zed Editor** - Two theme variants:
  - **Ado Hibana (Original)** - High-contrast cyberpunk aesthetic
  - **Ado Hibana Soft** - Eye-friendly for 8+ hour coding sessions
  - Full syntax highlighting for 50+ languages
  - Comprehensive UI element colors
  - Optimized for professional daily use

### 🚀 Application Launchers
- **Rofi** - Modern tabbed interface with four modes (Apps, Terminal, Files, Windows)
- Keyboard navigation and icon support
- Cyberpunk color scheme with cyan/magenta accents

### 🪟 Window Management
- **KWin Transparency Script** - Automatically dims inactive windows on secondary monitors
- Keeps active window and primary monitor at 100% opacity
- Works on both X11 and Wayland
- Configurable transparency levels

## 🎨 Color Palette

Consistent colors across all components:

| Color Name | Hex Code | Usage |
|------------|----------|-------|
| Void Navy | `#0f152e` | Deep background |
| Module Navy | `#1a2035` | Secondary elements |
| Cyan Accent | `#00f0ff` | Primary highlights |
| Magenta Glow | `#d000ff` | Secondary highlights |
| Silver Text | `#c0c0c0` | Main foreground |
| Blue | `#2b65ff` | Information/Links |
| Green | `#00e0b0` | Success states |
| Yellow | `#ffcc00` | Warnings |
| Red | `#ff4d4d` | Errors |

### Soft Theme Palette (Zed)
For the eye-friendly Zed theme variant:
- Soft Cyan: `#52c9d9` (30% desaturated)
- Soft Purple: `#b88dd4` (softer keywords)
- Soft Teal: `#6dc4a8` (strings)
- Soft Gold: `#e6be6e` (numbers)
- Lighter Background: `#1e2538` (25% lighter)

## 📋 System Requirements

- **OS**: Debian Trixie (or compatible Debian-based distribution)
- **Desktop Environment**: KDE Plasma 6
- **Display Server**: Wayland (X11 also supported for KWin script)
- **Privileges**: sudo access required
- **Network**: Internet connection for downloads
- **Font**: JetBrainsMono Nerd Font (auto-installed)

## 🚀 Quick Installation

### Install Everything (Recommended)

```bash
cd ~/Desktop/AdoRicing
./install.sh
```

This installs all components with default settings.

### Selective Installation

Install only specific components:

```bash
./install.sh --sddm       # Login theme
./install.sh --kitty      # Kitty terminal
./install.sh --starship   # Starship prompt
./install.sh --zsh        # ZSH configuration
./install.sh --fastfetch  # System info tool
./install.sh --kate       # Kate/KWrite theme
./install.sh --rofi       # Rofi launcher
./install.sh --zed        # Zed editor themes
./install.sh --fonts      # JetBrainsMono Nerd Font
./install.sh --kwin       # KWin transparency script
```

Combine multiple options:
```bash
./install.sh --kitty --starship --zsh --fastfetch
```

### Get Help

```bash
./install.sh --help
```

## 🎯 Post-Installation

After installation:

1. **Log out and back in** to see the SDDM theme
2. **Restart your terminal** or run: `source ~/.zshrc`
3. **Launch Rofi** with: `rofi -show drun`
4. **Open Kitty** to see the terminal theme
5. **Configure Kate/KWrite**: Settings → Configure Kate → Editor Component → Colors & Fonts → Select "Ado Hibana"
6. **Open Zed**: Theme is automatically set to "Ado Hibana Soft" (recommended for work)
7. **Verify KWin Script**: Open windows on secondary monitor to see transparency effect

## 📁 Project Structure

```
AdoRicing/
├── ado-sddm/              # SDDM login theme
│   ├── Main.qml
│   ├── Components/
│   └── Backgrounds/
├── kate/                  # Kate/KWrite editor theme
│   └── Ado-Hibana.theme
├── kwin/                  # KWin transparency script
│   ├── contents/
│   ├── metadata.json
│   └── install.sh
├── rofi/                  # Rofi launcher theme
│   ├── config.rasi
│   └── ado.rasi
├── terminal/              # Terminal configurations
│   ├── kitty/
│   ├── starship/
│   ├── zsh/
│   └── fastfetch/
├── zed/                   # Zed editor themes
│   ├── Ado-Hibana.json    # Both theme variants
│   └── settings.json
├── install.sh             # Automated installer
├── README.md              # This file
└── CHANGELOG.md           # Version history
```

## 🎨 Component Details

### SDDM Theme Features
- **Auto-focus**: Password field automatically focused on load
- **Auto-select**: Last logged-in user pre-selected
- **Animations**: Smooth fade-in effects and glowing borders
- **Customizable**: Edit `theme.conf` for colors, backgrounds, and behavior
- **Preview**: Test with `sddm-greeter --test-mode --theme /usr/share/sddm/themes/ado-theme`

### Zed Editor - Two Themes

#### Ado Hibana (Original)
- High-contrast cyberpunk aesthetic
- Bright cyan (#00f0ff) and magenta (#d000ff) accents
- Best for: Demos, screenshots, short sessions

#### Ado Hibana Soft (Recommended)
- Eye-friendly for 8+ hour coding sessions
- 30% desaturated colors
- 25% lighter background
- Warmer color temperature (reduced blue light)
- Better comment visibility
- WCAG AAA compliant (7.8:1 contrast ratio)

**Switch themes in Zed**: `Cmd/Ctrl + Shift + P` → "Select Theme"

**Expected syntax colors**:
- Keywords (if, for, class): Purple/Magenta
- Functions: Cyan
- Strings: Teal/Green
- Numbers: Gold/Yellow
- Types: Blue
- Comments: Grey-Blue (italic)

### KWin Transparency Script
- **Purpose**: Automatically dim inactive windows on secondary monitors
- **Primary Monitor**: Always 100% opacity
- **Secondary Monitor (Active)**: 100% opacity
- **Secondary Monitor (Inactive)**: 85% opacity (configurable)
- **Requirements**: Multiple monitors, compositor enabled
- **Configuration**: Edit `kwin/contents/code/main.js` to change transparency level
- **Test**: Run `./kwin/test.sh` to verify installation

### Terminal Setup
- **Kitty**: 95% transparency with blur, beam cursor, JetBrainsMono font
- **Starship**: Git integration, language version display, custom separators
- **Fastfetch**: Ado branding, three-category layout (System/Desktop/Hardware)
- **ZSH**: Oh My Zsh with Starship prompt, auto-run Fastfetch on startup

### Rofi Launcher
- **Modes**: Apps (`-show drun`), Terminal, Files, Windows
- **Navigation**: Alt+Left/Right for tabs, Arrow keys for selection
- **Icons**: Full icon support with fallbacks
- **Theme**: Cyberpunk colors matching overall aesthetic

## 🔧 Customization

### Change SDDM Background
Edit `/usr/share/sddm/themes/ado-theme/theme.conf`:
```conf
[General]
background=Backgrounds/YourImage.jpg
```

### Adjust Kitty Transparency
Edit `~/.config/kitty/kitty.conf`:
```conf
background_opacity 0.90  # Change from 0.95
```

### Modify Starship Prompt
Edit `~/.config/starship.toml` to customize prompt segments and colors.

### Change KWin Transparency Level
Edit `~/.local/share/kwin/scripts/ado-monitor-transparency/contents/code/main.js`:
```javascript
const TRANSPARENCY_LEVEL = 0.70;  // Change from 0.85
```
Then run: `cd kwin && ./install.sh`

### Customize Zed Colors
Edit `~/.config/zed/themes/Ado-Hibana.json` directly to tweak colors.
Zed will reload automatically.

### Adjust Rofi Theme
Edit `~/.config/rofi/ado.rasi` to change colors and layout.

## 🐛 Troubleshooting

### SDDM Theme Not Showing
```bash
# Check configuration
cat /etc/sddm.conf.d/ado-theme.conf

# Should show:
# [Theme]
# Current=ado-theme

# Reinstall if needed
sudo ./install.sh --sddm
```

### Zed Syntax Highlighting Not Working
```bash
# Verify theme file exists
ls ~/.config/zed/themes/Ado-Hibana.json

# Reinstall theme
./install.sh --zed

# Check theme is active
grep theme ~/.config/zed/settings.json

# Should show: "theme": "Ado Hibana Soft"
```

### KWin Script Not Working
```bash
# Run diagnostic
cd kwin
./test.sh

# Check if loaded
qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.isScriptLoaded "ado-monitor-transparency"

# Reinstall if needed
./install.sh

# View logs
journalctl --user -f | grep AdoTransparency
```

### Terminal Colors Wrong
```bash
# Ensure font is installed
fc-list | grep JetBrains

# Reload ZSH config
source ~/.zshrc

# Restart terminal
```

### Rofi Not Launching
```bash
# Check installation
which rofi

# Test with
rofi -show drun

# Reinstall if needed
./install.sh --rofi
```

## 🏥 Eye Health (Zed Users)

When using Zed for extended periods:

1. **Use Ado Hibana Soft** theme for daily work
2. **Follow 20-20-20 rule**: Every 20 minutes, look 20 feet away for 20 seconds
3. **Adjust monitor brightness** to match ambient lighting
4. **Proper positioning**: Monitor 20-26 inches away, top at eye level
5. **Take breaks**: Stand up every hour
6. **Blue light filter**: Enable system-level filter after sunset
7. **Increase font size** if you find yourself leaning forward

## 📚 Configuration Files

After installation, configs are located at:

```
SDDM:      /usr/share/sddm/themes/ado-theme/
Kitty:     ~/.config/kitty/kitty.conf
Starship:  ~/.config/starship.toml
Fastfetch: ~/.config/fastfetch/ado.jsonc
Kate:      ~/.local/share/org.kde.syntax-highlighting/themes/
Rofi:      ~/.config/rofi/
Zed:       ~/.config/zed/themes/Ado-Hibana.json
ZSH:       ~/.zshrc
KWin:      ~/.local/share/kwin/scripts/ado-monitor-transparency/
```

## 🔄 Updating

Pull latest changes:
```bash
cd ~/Desktop/AdoRicing
git pull
./install.sh
```

Backups are automatically created with timestamps.

## 🗑️ Uninstallation

### Remove All Components
```bash
# SDDM
sudo rm -rf /usr/share/sddm/themes/ado-theme
sudo rm /etc/sddm.conf.d/ado-theme.conf

# Kitty
rm ~/.config/kitty/kitty.conf

# Starship
rm ~/.config/starship.toml

# Fastfetch
rm -rf ~/.config/fastfetch

# Kate
rm ~/.local/share/org.kde.syntax-highlighting/themes/Ado-Hibana.theme

# Rofi
rm -rf ~/.config/rofi

# Zed
rm ~/.config/zed/themes/Ado-Hibana.json
rm ~/.config/zed/settings.json

# KWin Script
rm -rf ~/.local/share/kwin/scripts/ado-monitor-transparency
kwriteconfig6 --file kwinrc --group Plugins --key ado-monitor-transparencyEnabled --delete
qdbus6 org.kde.KWin /KWin reconfigure

# ZSH (restore from backup)
mv ~/.zshrc.backup.* ~/.zshrc
```

## 🎓 Tips & Tricks

### Quick Rofi Launch
Add to KDE keyboard shortcuts:
- Command: `rofi -show drun`
- Shortcut: `Meta + Space` (or your preference)

### Test SDDM Without Logout
```bash
sddm-greeter --test-mode --theme /usr/share/sddm/themes/ado-theme
```

### Zed Theme Switching Aliases
Add to `~/.zshrc`:
```bash
alias zed-work='sed -i "s/Ado Hibana\"/Ado Hibana Soft\"/g" ~/.config/zed/settings.json'
alias zed-demo='sed -i "s/Ado Hibana Soft\"/Ado Hibana\"/g" ~/.config/zed/settings.json'
```

### Monitor KWin Script in Real-Time
```bash
journalctl --user -f | grep AdoTransparency
```

### Fastfetch on Demand
```bash
fastfetch --config ~/.config/fastfetch/ado.jsonc
```

## 🤝 Contributing

Contributions are welcome! Areas for improvement:
- Additional terminal emulator support
- Light theme variants
- More Rofi modes
- Additional language support for Kate/Zed
- Plasma color scheme integration

## 🙏 Credits & Acknowledgments

- **Inspiration**: Ado - "Hibana" World Tour 2025
- **SDDM Base**: Marian Arlt - Sugar Candy theme
- **Fonts**: JetBrains - JetBrainsMono, Ryanoasis - Nerd Fonts
- **Starship**: Starship Team - Cross-shell prompt
- **Desktop Environment**: KDE Team - Plasma 6

## 📄 License

GPL-3.0 License

## 📞 Support

For issues or questions:
1. Check `CHANGELOG.md` for known issues
2. Review troubleshooting section above
3. Check component-specific logs
4. Ensure system meets requirements

## 🎯 Version Information

**Current Version**: 1.1.0  
**Last Updated**: 2025-01-XX  
**Tested On**: Debian Trixie, KDE Plasma 6.3.6, Wayland  
**Status**: Stable ✅

---

**Enjoy your new Ado Hibana themed desktop! 🔥**

*"Hibana" - Like a spark, ignite your creativity.*