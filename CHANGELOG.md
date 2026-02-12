# Changelog

All notable changes to the AdoRicing theme suite are documented in this file.

## [1.0.0] - 2025-01-XX

### 🎉 Initial Release

Complete theme suite for Debian Trixie/KDE 6 Wayland with Ado Hibana aesthetic.

### ✨ Added

#### SDDM Login Theme
- Custom QML-based SDDM theme with cyberpunk design
- Animated entrance with staggered fade-in effects
- User profile picture picker with hover animations
- Auto-focus on password field for immediate login
- Auto-select default/last user on startup
- Glowing password field with pulsing border animation
- System buttons (shutdown, reboot, hibernate, suspend)
- Session selector integration
- Clock and date display
- Custom background support
- Blur effects configuration

#### Terminal Customization
- **Kitty Terminal**
  - Complete Ado Hibana color scheme
  - 95% transparency with blur support
  - Beam cursor style
  - JetBrainsMono Nerd Font integration
  - Window padding configuration

- **Starship Prompt**
  - Segmented pill design (directory → git → languages)
  - Git branch with cyan highlighting
  - Git status indicator (red "!")
  - Git metrics (+/- lines changed)
  - Python version display
  - Node.js version display
  - Cyan arrow prompt (➜)
  - Error state indication (red arrow)

- **ZSH Configuration**
  - Oh My Zsh integration
  - Starship prompt initialization
  - Fastfetch auto-run on terminal start

- **Fastfetch System Info**
  - Custom Ado branding with logo
  - Three-category layout: System, Desktop, Hardware
  - Color-coded sections (Blue, Cyan, Magenta)
  - Custom separator (➜)
  - Package count, disk usage, battery display

#### Application Launchers
- **Rofi Launcher**
  - Modern tabbed interface
  - Four modes: Apps, Terminal, Files, Windows
  - Hover selection support
  - Keyboard navigation (Alt+Left/Right for tabs)
  - Icon support
  - Cyberpunk color scheme with cyan/magenta accents

#### Editor Themes
- **Kate/KWrite**
  - Complete syntax highlighting theme
  - Support for 40+ languages
  - Custom styles for:
    - HTML/CSS/JavaScript
    - Python, Rust, C++
    - Markdown with styled headers
    - Bash scripting
    - Diff viewing
  - Editor color customization (line numbers, current line, selection)

- **Zed Editor**
  - Two theme variants for different use cases
  - **Ado Hibana (Original)**: High-contrast cyberpunk theme
    - Vibrant cyan (#00f0ff) and magenta (#d000ff) accents
    - Deep navy background (#182042)
    - Maximum visual impact for demos and short sessions
  - **Ado Hibana Soft (Recommended)**: Eye-friendly for 8+ hour coding
    - 30% desaturated colors to reduce eye strain
    - Softer cyan (#52c9d9) and purple (#b88dd4) keywords
    - Lighter background (#1e2538) with reduced contrast
    - Warmer color temperature to minimize blue light
    - Better comment visibility (#7a8299)
    - Optimized for professional daily use
  - Comprehensive syntax highlighting for 50+ languages
  - Terminal color integration
  - Markdown rendering support
  - Eye-comfort editor settings included

### 🔧 Fixed

#### SDDM Theme Critical Fixes
1. **Password Field Focus Issue**
   - Added `Component.onCompleted` auto-focus in `Input.qml`
   - Set `focus: true` on password TextField
   - Removed conditional focus logic that prevented auto-focus
   - Added `focusPasswordField()` function for manual focusing

2. **Default User Selection**
   - Fixed `UserPicker.qml` to auto-select user on load
   - Added `Component.onCompleted` handler to select first/last user
   - Implemented `userSelected` signal properly
   - Added `Connections` block in `LoginForm.qml` to handle user selection
   - Removed broken `userList` property access

3. **QML Structure Issues**
   - Fixed property exposure in UserPicker component
   - Added proper signal handling between components
   - Removed duplicate event handlers

### 📦 Installation System

#### Comprehensive Install Script
- Automated dependency installation
  - SDDM, Qt6 components, QML modules
  - Kitty terminal
  - Rofi launcher
  - ZSH shell
  - Git, Curl utilities
  - Fastfetch system info tool

- **Font Management**
  - Automatic JetBrainsMono Nerd Font download
  - Font cache rebuilding
  - Duplicate detection

- **Starship Installation**
  - Official installer integration
  - Automatic PATH configuration

- **Configuration Backup System**
  - Timestamped backups of existing configs
  - Non-destructive installation
  - Easy rollback capability

- **SDDM Configuration**
  - Automatic theme activation
  - `/etc/sddm.conf.d/` integration
  - Theme file deployment

- **Shell Configuration**
  - ZSH as default shell (with user confirmation)
  - Oh My Zsh installation
  - Starship prompt integration
  - Fastfetch auto-run setup

- **Colorful Output**
  - Progress indicators
  - Color-coded status messages
  - Step numbering (1/8, 2/8, etc.)
  - Installation summary

### 📚 Documentation

#### README.md
- Complete feature list with emoji sections
- Installation instructions (quick and manual)
- Usage examples for all components
- Customization guide
- Troubleshooting section with common issues
- Project structure documentation
- Uninstallation instructions
- Credits and licensing

#### TODO.md
- Structured task tracking
- Completed tasks checklist
- Priority-based organization
- Future enhancement ideas
- Known issues section

### 🎨 Color Palette

Consistent colors across all components:
- **Void Navy**: `#0f152e` - Deep background
- **Module Navy**: `#1a2035` - Secondary elements
- **Cyan Accent**: `#00f0ff` - Primary highlights
- **Magenta Glow**: `#d000ff` - Secondary highlights
- **Silver Text**: `#c0c0c0` - Main foreground
- **Blue**: `#2b65ff` - Information/Links
- **Green**: `#00e0b0` - Success states
- **Yellow**: `#ffcc00` - Warnings
- **Red**: `#ff4d4d` - Errors

### 🏗️ Project Structure

```
AdoRicing/
├── ado-sddm/              # SDDM login theme
├── kate/                  # Kate/KWrite editor theme
├── rofi/                  # Rofi launcher theme
├── terminalCustomization/ # Terminal configs
│   ├── kitty/            # Kitty terminal
│   ├── starship/         # Starship prompt
│   └── zsh/              # ZSH & Fastfetch
├── install.sh            # Automated installer
├── README.md             # Documentation
├── TODO.md               # Task tracking
└── CHANGELOG.md          # This file
```

### 📋 System Requirements

- Debian Trixie (or compatible Debian-based distribution)
- KDE Plasma 6
- Wayland display server
- `sudo` privileges
- Internet connection (for downloads)

### 🙏 Acknowledgments

- **Ado** - Inspiration from "Hibana" World Tour 2025
- **Marian Arlt** - Original SDDM Sugar Candy theme
- **JetBrains** - JetBrainsMono Nerd Font
- **Ryanoasis** - Nerd Fonts project
- **Starship Team** - Cross-shell prompt
- **KDE Team** - Plasma desktop environment

---

**New Knowledge Detected**: Complete themeing system with focus management fixes, auto-user selection, comprehensive installation automation, and multi-application color scheme coordination for KDE 6 Wayland environment.