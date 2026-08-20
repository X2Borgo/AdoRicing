# Changelog

All notable changes to AdoRicing are documented in this file.

## [1.3.0] - 2026-03-26

### Added

- `hypr/` config payload is now installed by default in the Hyprland profile
- New installer flag: `--hypr-config`
- Automatic backup of existing `~/.config/hypr` before applying repo config
- Automatic execute-bit fixes for `hypr/scripts`, `hypr/UserScripts`, and `initial-boot.sh`

### Changed

- Updated Hypr startup behavior to launch Quickshell via:
  - `exec-once = quickshell -p $HOME/.config/quickshell/AdoRicing/main.qml`
- Switched Hypr palette to Ado colors in `hypr/wallust/wallust-hyprland.conf`
- Retuned decoration defaults in `hypr/UserConfigs/UserDecorations.conf`
- Rethemed lock screens in:
  - `hypr/hyprlock.conf`
  - `hypr/hyprlock-2k.conf`
  - `hypr/hyprlock-1080p.conf`

## [1.2.0] - 2026-03-26

### Changed

- Refocused the project around Hyprland on Wayland instead of KDE Plasma as the default target
- Changed the top-level installer to a Hyprland-first default set
- Reframed SDDM as optional instead of part of the default installation path
- Marked `kwin/` as a legacy Plasma-only component

### Added

- `--hyprland` installer profile
- `--quickshell` installer option
- Quickshell config deployment into `~/.config/quickshell/AdoRicing/`
- Automatic Quickshell asset copy for the Ado icon used by the panel

### Fixed

- Removed Plasma-specific assumptions from the default installation flow
- Made the Quickshell panel portable by removing the old absolute asset path
- Stopped the installer from claiming Plasma components as the primary target

## [1.0.0] - 2025-01-XX

### Initial Release

Complete theme suite for Debian Trixie / KDE Plasma 6 Wayland with the Ado Hibana aesthetic.

### Added

- Custom SDDM theme
- Kitty theme
- Starship prompt
- ZSH setup
- Fastfetch branding
- Rofi theme
- Kate/KWrite theme
- Zed theme pack
- Installer automation
