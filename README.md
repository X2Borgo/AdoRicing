# AdoRicing - Ado Hibana Theme Suite

A Hyprland-first theming suite for Debian Trixie/Wayland, inspired by Ado's "Hibana" World Tour 2025. The project now focuses on portable userland theming plus an optional SDDM greeter, while older Plasma-specific pieces remain in the repo as legacy components.

![Version](https://img.shields.io/badge/version-1.3.0-blue)
![Platform](https://img.shields.io/badge/platform-Debian%20Trixie-red)
![WM](https://img.shields.io/badge/WM-Hyprland-cyan)
![Display](https://img.shields.io/badge/display-Wayland-green)

## What's Included

### Terminal
- Kitty theme with the Ado Hibana palette
- Starship prompt with segmented styling and git integration
- ZSH setup with Oh My Zsh
- Fastfetch branding and themed output

### Launchers And Editors
- Rofi theme for app launching and quick switching
- Zed themes: `Ado Hibana` and `Ado Hibana Soft`
- Kate/KWrite syntax theme for users who still use Kate outside Plasma

### Wayland Shell Layer
- Caelestia Shell support via Hypr startup command
- Waybar fallback when Caelestia cannot start
- A full `hypr/` config tree installed into `~/.config/hypr`
- Ado-styled Hyprland colors, borders, and Hyprlock defaults

### Optional Login Theme
- SDDM greeter theme, still usable if your Hyprland session starts from SDDM

### Legacy Plasma Component
- `kwin/` is kept for archival compatibility but is not part of the Hyprland path

## System Requirements

- Debian Trixie or a compatible Debian-based distribution
- Hyprland on Wayland
- `sudo` access
- Internet connection for downloads
- JetBrainsMono Nerd Font

Optional:
- SDDM if you want the greeter theme
- Caelestia CLI/shell or Quickshell installed separately for panel UI

## Quick Installation

Default install is now the Hyprland-oriented set:

```bash
cd ~/Desktop/AdoRicing
./install.sh
```

That installs:
- Hyprland config (`~/.config/hypr`)
- Local Caelestia shell link (`~/.config/quickshell/caelestia` -> `~/Desktop/AdoRicing/shell`)
- Kitty
- Starship
- ZSH
- Fastfetch
- Rofi
- Zed
- Fonts
- Quickshell config

## Selective Installation

```bash
./install.sh --hyprland    # Same as default
./install.sh --hypr-config # Install only ~/.config/hypr payload
./install.sh --caelestia-shell # Link local shell/ repo into quickshell config path
./install.sh --kitty
./install.sh --starship
./install.sh --zsh
./install.sh --fastfetch
./install.sh --rofi
./install.sh --zed
./install.sh --fonts
./install.sh --quickshell
./install.sh --kate
./install.sh --sddm       # Optional greeter theme
./install.sh --kwin       # Legacy Plasma-only component
```

Combine options as needed:

```bash
./install.sh --kitty --rofi --zed --quickshell
```

Help:

```bash
./install.sh --help
```

## Hyprland Notes

The installer now deploys a complete Hypr config tree to:

```bash
~/.config/hypr/
```

If you install the Quickshell config, it is placed at:

```bash
~/.config/quickshell/AdoRicing/main.qml
```

The installed Hypr startup config now launches `~/.config/hypr/scripts/LaunchShell.sh`, which:

```conf
exec-once = $scriptsDir/LaunchShell.sh
```

It tries the local Caelestia config first, then installed Caelestia configs, and finally falls back to Waybar if Caelestia fails during startup.

If you are using Nix flakes, add the Caelestia shell input to your flake configuration:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

The shipped Hypr config has been adjusted to the Ado palette (cyan/magenta accents, dark navy background, and tuned Hyprlock styling). For Caelestia installation and CLI usage, refer to the official repositories:

- https://github.com/caelestia-dots/shell
- https://github.com/caelestia-dots/scripts

## Project Structure

```text
AdoRicing/
├── ado-sddm/              # Optional SDDM theme
├── hypr/                  # Hyprland config payload (installed to ~/.config/hypr)
├── kate/                  # Kate/KWrite theme
├── kwin/                  # Legacy Plasma-only script
├── quickshell/            # Quickshell panel config
├── rofi/                  # Rofi launcher theme
├── terminal/              # Kitty, Starship, ZSH, Fastfetch
├── zed/                   # Zed themes and settings
├── install.sh             # Hyprland-first installer
├── README.md
└── CHANGELOG.md
```

## Component Details

### Kitty
- 95% background opacity
- JetBrainsMono Nerd Font
- Ado Hibana accent colors

### Starship
- Segmented prompt layout
- Git status and branch info
- Language/runtime modules

### Fastfetch
- Ado branding
- Themed color blocks
- Ready for Wayland desktop info output

### Zed
- `Ado Hibana` for high-contrast sessions
- `Ado Hibana Soft` for long work sessions

### Quickshell
- Simple top bar layout
- Music, network, volume, battery, and clock modules
- Available as an optional panel config

### Hyprland Config
- Ships `hyprland.conf`, `hypridle.conf`, `hyprlock*.conf`, monitor/workspace files, and helper scripts
- Includes an Ado color palette in `wallust/wallust-hyprland.conf`
- Applies Ado border and lock screen styling in `UserConfigs/UserDecorations.conf` and `hyprlock*.conf`

### SDDM
- Custom greeter visuals
- Animated entry
- User/session controls
- Still optional for display-manager-based login flows

## Customization

### Adjust Kitty Transparency

Edit `~/.config/kitty/kitty.conf`:

```conf
background_opacity 0.90
```

### Modify Starship Prompt

Edit `~/.config/starship.toml`.

### Customize Zed Colors

Edit `~/.config/zed/themes/Ado-Hibana.json`.

### Adjust Rofi Theme

Edit `~/.config/rofi/ado.rasi`.

### Tweak Quickshell

Edit `~/.config/quickshell/AdoRicing/main.qml`.

### Tweak Hyprland Theme

Edit:
- `~/.config/hypr/wallust/wallust-hyprland.conf` (palette)
- `~/.config/hypr/UserConfigs/UserDecorations.conf` (borders, gaps, blur, shadows)
- `~/.config/hypr/hyprlock.conf` (lock-screen visuals)

### Change The SDDM Background

Edit `/usr/share/sddm/themes/ado-theme/theme.conf`:

```conf
[General]
background=Backgrounds/YourImage.jpg
```

## Troubleshooting

### Quickshell Does Not Start

```bash
which quickshell
quickshell -p ~/.config/quickshell/AdoRicing/main.qml
```

If `quickshell` is missing, install the binary first. The repo only installs the config.

### Caelestia Shell Does Not Start

```bash
ls ~/.config/quickshell/caelestia/shell.qml
which qs
qs -p ~/.config/quickshell/caelestia/shell.qml
```

If `qs` is missing, install Quickshell first. If `shell.qml` is missing, run `./install.sh --caelestia-shell`.

Linking `shell/` is not enough by itself. The shell also needs the compiled `Caelestia` QML plugin and a Quickshell build that provides `qs.utils`. If those modules are missing, the launcher now falls back to Waybar and writes the startup error to:

```bash
~/.cache/adoricing/shell-launch.log
```

### Waybar Still Appears

```bash
pkill -x waybar
systemctl --user disable --now waybar.service
hyprctl reload
```

Then run `./install.sh --hypr --caelestia-shell` to reapply startup config and scripts.

### Hyprland Config Not Applied

```bash
hyprctl reload
grep -n "AdoRicing" ~/.config/hypr/hyprlock.conf
```

### Rofi Not Launching

```bash
which rofi
rofi -show drun
```

### Kitty Theme Not Applied

```bash
ls ~/.config/kitty/kitty.conf
fc-list | grep JetBrains
```

### Zed Theme Missing

```bash
ls ~/.config/zed/themes/Ado-Hibana.json
grep theme ~/.config/zed/settings.json
```

### SDDM Theme Not Showing

```bash
cat /etc/sddm.conf.d/ado-theme.conf
```

Expected:

```conf
[Theme]
Current=ado-theme
```

## Legacy Plasma Note

The `kwin/` directory is still present, but it is now explicitly legacy. It exists for older Plasma setups and is not wired into the Hyprland-first workflow.

## Updating

```bash
cd ~/Desktop/AdoRicing
git pull
./install.sh
```

## Version Information

**Current Version**: 1.3.0  
**Last Updated**: 2026-03-26  
**Target**: Debian Trixie, Hyprland, Wayland  
**Status**: Active
