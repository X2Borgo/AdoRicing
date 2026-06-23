# AdoRicing - Ado Hibana Theme Suite

A Hyprland-first theming suite for Debian Trixie / Wayland, inspired by Ado's "Hibana" World Tour 2025. The project focuses on a portable userland rice built around Hyprland, the DankMaterialShell panel, and the Ado Hibana palette (cyan/magenta accents on a dark navy base). Older Plasma-specific pieces (KWin, Kate) remain in the repo as optional/legacy components.

> **Source of truth:** the code in this repo is authoritative. This README describes the current setup; if it ever disagrees with `install.sh` or the config files, the files win.

![Version](https://img.shields.io/badge/version-1.3.0-blue)
![Platform](https://img.shields.io/badge/platform-Debian%20Trixie-red)
![WM](https://img.shields.io/badge/WM-Hyprland-cyan)
![Shell](https://img.shields.io/badge/shell-DankMaterialShell-magenta)
![Display](https://img.shields.io/badge/display-Wayland-green)

## Current Stack

| Role | Tool |
| --- | --- |
| Compositor / window manager | Hyprland (Wayland) |
| Desktop shell / top bar | DankMaterialShell (DMS), Waybar fallback |
| Code editor | Zed |
| Browser | Zen, with Chrome as fallback |
| Terminal | Kitty |
| App launcher | Rofi |
| Prompt | Starship |
| Login (optional) | SDDM |

## What's Included

### Wayland Shell Layer
- **DankMaterialShell (DMS)** as the primary top bar / desktop shell, started by `hypr/scripts/LaunchShell.sh` (`dms run --daemon`)
- **Waybar** automatic fallback if `dms` is missing or fails to start
- A complete `hypr/` config tree (Lua-based, Hyprland 0.55+ Lua API) installed into `~/.config/hypr`
- DMS integration files in `hypr/dms/` (colors, layout, cursor, window rules)
- `dms-plugins/` — a `DockerLauncher` plugin for DMS
- Ado-styled Hyprland colors, borders, gaps, blur, and Hyprlock defaults

### Terminal
- Kitty theme with the Ado Hibana palette (95% background opacity, JetBrainsMono Nerd Font)
- Starship prompt with segmented styling and git integration
- ZSH setup with Oh My Zsh (runs Fastfetch + Starship on launch)
- Fastfetch branding and themed output

### Editor And Launcher
- Zed themes: `Ado Hibana` (high-contrast) plus tuned `settings.json` and `keymap.json`
- Rofi theme for app launching and quick switching (`config.rasi` + `ado.rasi`)

### Browser
- Zen is the primary browser (`SUPER + ALT + Z`)
- Chrome is kept as the fallback browser (`SUPER + ALT + G`)
- Browser profiles are treated as runtime state and are not installed or symlinked by this repo

### Wallpapers And Assets
- `Instal-wallpapers/` — curated wallpaper sets (`ado`, `anime`, `anime-girl`, `lol`, `paesaggi`, `shrek`, `ygo`)
- `useful_images/` — Ado-themed logos, icons, and avatars used by the shell/panel

### Optional Login Theme
- SDDM greeter theme, usable if your Hyprland session starts from SDDM

### Legacy / Archival Components
- `kwin/` — Plasma-only KWin script, kept for archival compatibility, not part of the Hyprland path
- `kate/` — Kate/KWrite syntax theme for users who still use Kate outside Plasma

## System Requirements

- Debian Trixie or a compatible Debian-based distribution
- Hyprland on Wayland (0.55+ for the Lua config)
- `sudo` access
- Internet connection for downloads
- JetBrainsMono Nerd Font (installed by `--fonts`)

Optional:
- `dms` (DankMaterialShell CLI/binary) installed separately for the panel UI — the repo ships config, not the binary
- Quickshell (`qs`) for the shell runtime
- SDDM if you want the greeter theme

## Quick Installation

Default install is the Hyprland-oriented set:

```bash
cd ~/Desktop/AdoRicing
./install.sh
```

That installs:
- Hyprland config (`~/.config/hypr`)
- Local shell repo link (`~/.config/quickshell/caelestia` -> `~/Desktop/AdoRicing/shell`, the DankMaterialShell source)
- Kitty, Starship, ZSH, Fastfetch
- Rofi, Zed
- Fonts
- Quickshell panel config

> Note: the `--caelestia-shell` flag and the `caelestia` link path are legacy names. The linked `shell/` submodule is **DankMaterialShell**, and the running shell is launched via `dms run`.

## Selective Installation

```bash
./install.sh --hyprland         # Hyprland-focused set (same as default)
./install.sh --hypr-config      # Install only the ~/.config/hypr payload
./install.sh --caelestia-shell  # Link local shell/ (DankMaterialShell) into quickshell config path
./install.sh --quickshell       # Quickshell panel config
./install.sh --kitty
./install.sh --starship
./install.sh --zsh
./install.sh --fastfetch
./install.sh --rofi
./install.sh --zed
./install.sh --fonts
./install.sh --kate             # Legacy Kate/KWrite theme
./install.sh --sddm             # Optional greeter theme
./install.sh --kwin             # Legacy Plasma-only component
./install.sh --all              # Everything, including legacy pieces
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

The installer deploys a complete Lua-based Hypr config tree to:

```bash
~/.config/hypr/
```

The entry point is `hyprland.lua`, which `require`s the module tree under `configs/`, `UserConfigs/`, `monitors`, `workspaces`, and `dms/` (e.g. `require("dms.cursor")`). Startup apps are registered in `configs/Startup_Apps.lua` / `UserConfigs/Startup_Apps.lua`, which autostart the shell launcher:

```lua
table.insert(ctx.autostart, { cmd = (vars["scriptsDir"] or "") .. "/LaunchShell.sh" })
```

`LaunchShell.sh` behavior:
1. If `dms` is on `PATH`, it kills any stray Waybar and runs `dms run --daemon`, then waits for the shell to come up.
2. If `dms` is missing or fails to start within the timeout, it falls back to Waybar and sends a notification.
3. The launch log is written to `${XDG_RUNTIME_DIR:-/tmp}/dms-launch.log`.

The Quickshell panel config (`--quickshell`) is a separate, simpler panel installed at:

```bash
~/.config/quickshell/AdoRicing/main.qml
```

## Project Structure

```text
AdoRicing/
├── hypr/                  # Hyprland Lua config payload (installed to ~/.config/hypr)
│   ├── hyprland.lua       # Entry point (requires the module tree)
│   ├── configs/           # Core configs: Keybinds, Startup_Apps, SystemSettings, WindowRules, ...
│   ├── UserConfigs/       # User overrides: decorations, animations, keybinds, settings
│   ├── dms/               # DankMaterialShell integration (colors, layout, cursor, windowrules)
│   ├── scripts/           # Helper scripts, incl. LaunchShell.sh
│   ├── UserScripts/       # Wallpaper, weather, rofi helpers
│   ├── animations/        # Animation presets
│   ├── hyprlock*.lua      # Lock-screen configs (default + 1080p/2k variants)
│   └── hypridle.lua       # Idle/lock daemon config
├── shell/                 # DankMaterialShell source (git submodule)
├── dms-plugins/           # DMS plugins (DockerLauncher)
├── quickshell/            # Standalone Quickshell panel config
├── terminal/              # Kitty, Starship, ZSH, Fastfetch
├── zed/                   # Zed theme, settings, keymap
├── rofi/                  # Rofi launcher theme
├── Instal-wallpapers/     # Wallpaper sets
├── useful_images/         # Ado-themed assets used by the shell/panel
├── ado-sddm/              # Optional SDDM theme
├── kate/                  # Legacy Kate/KWrite theme
├── kwin/                  # Legacy Plasma-only script
├── install.sh             # Hyprland-first installer
├── README.md
└── CHANGELOG.md
```

## Customization

### Tweak the Hyprland theme
Edit the Lua configs (Hyprland reloads them via `hyprctl reload`):
- `~/.config/hypr/dms/colors.lua` — palette shared with DMS
- `~/.config/hypr/UserConfigs/UserDecorations.lua` — borders, gaps, blur, shadows
- `~/.config/hypr/hyprlock.lua` (and `hyprlock-1080p.lua` / `hyprlock-2k.lua`) — lock-screen visuals
- `~/.config/hypr/UserConfigs/UserKeybinds.lua` — keybindings
- `~/.config/hypr/wallust/wallust-hyprland.lua` — wallust palette template

### Adjust the DMS panel
DMS is configured through its own config and the `hypr/dms/` integration files (`colors.lua`, `layout.lua`, `windowrules.lua`). See the DankMaterialShell project for shell-side settings:
- https://github.com/AvengeMedia/DankMaterialShell

### Adjust Kitty transparency
Edit `~/.config/kitty/kitty.conf`:

```conf
background_opacity 0.90
```

### Modify Starship prompt
Edit `~/.config/starship.toml`.

### Customize Zed colors
Edit `~/.config/zed/themes/Ado-Hibana.json`.

### Adjust Rofi theme
Edit `~/.config/rofi/ado.rasi`.

### Tweak the standalone Quickshell panel
Edit `~/.config/quickshell/AdoRicing/main.qml`.

### Change the SDDM background
Edit `/usr/share/sddm/themes/ado-theme/theme.conf`:

```conf
[General]
background=Backgrounds/YourImage.jpg
```

## Troubleshooting

### Shell (DMS) does not start
```bash
which dms
cat "${XDG_RUNTIME_DIR:-/tmp}/dms-launch.log"
```
If `dms` is missing, install DankMaterialShell. `LaunchShell.sh` falls back to Waybar when `dms` is unavailable.

### Waybar appears instead of DMS
That is the fallback path — it means `dms` was not found or failed to start. Check the log above, then:
```bash
pkill -x waybar
hyprctl reload
```

### Hyprland config not applied
```bash
hyprctl reload
ls ~/.config/hypr/hyprland.lua
```

### Quickshell panel does not start
```bash
which quickshell
quickshell -p ~/.config/quickshell/AdoRicing/main.qml
```

### Rofi not launching
```bash
which rofi
rofi -show drun
```

### Kitty theme not applied
```bash
ls ~/.config/kitty/kitty.conf
fc-list | grep JetBrains
```

### Zed theme missing
```bash
ls ~/.config/zed/themes/Ado-Hibana.json
grep theme ~/.config/zed/settings.json
```

### SDDM theme not showing
```bash
cat /etc/sddm.conf.d/ado-theme.conf
```
Expected:
```conf
[Theme]
Current=ado-theme
```

## Legacy Notes

- `kwin/` is Plasma-only and not wired into the Hyprland workflow; kept for archival use.
- `kate/` ships a Kate/KWrite syntax theme for users who still use Kate outside Plasma.
- The `caelestia` naming in the installer (`--caelestia-shell`, the link path) is historical; the actual shell is DankMaterialShell.

## Updating

```bash
cd ~/Desktop/AdoRicing
git pull
git submodule update --init --recursive   # refresh the DankMaterialShell source
./install.sh
```

## Version Information

**Current Version**: 1.3.0
**Last Updated**: 2026-06-19
**Target**: Debian Trixie, Hyprland (Wayland)
**Shell**: DankMaterialShell (Waybar fallback)
**Browser**: Zen, with Chrome fallback
**Status**: Active
