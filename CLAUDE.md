# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

AdoRicing is a Hyprland-first theming suite ("rice") for Debian Trixie / Wayland, built around the Ado Hibana palette (cyan/magenta on dark navy). It is a dotfiles payload plus an installer — there is no build system, package manager manifest, or test suite. The code in this repo is the source of truth; the README describes it but the config files and `install.sh` win on any disagreement.

## Commands

```bash
./install.sh                 # default: Hyprland-oriented set (hypr config, shell link, kitty, starship, zsh, fastfetch, rofi, zed, fonts, quickshell)
./install.sh --hypr-config   # only the ~/.config/hypr payload
./install.sh --kitty --rofi  # flags combine; see --help for the full list
./install.sh --all           # everything, including legacy pieces (kate, kwin, sddm)
```

Verification is manual: after changing Hyprland Lua config, the check is `hyprctl reload` on a live Hyprland session (there is no lint/test step). Shell scripts in `hypr/scripts/` must keep their executable bits.

The DMS launch log is written to `${XDG_RUNTIME_DIR:-/tmp}/dms-launch.log` — useful when debugging shell startup.

## Architecture

### hypr/ — Lua-based Hyprland config (installed to ~/.config/hypr)

Targets Hyprland 0.55+ and its **Lua API** (`hl.*`), not the classic hyprlang `.conf` format. The repo is mid-migration from `.conf` to `.lua`; deleted `.conf` files in git status reflect that. `hypr/hyprland.lua` is the entry point:

- It builds a shared global context `_G.ADO_HYPR` (`ctx.vars` for paths like `scriptsDir`, `ctx.autostart` for startup commands) and `require`s the module tree with a `require_once` guard.
- **Load order matters**: `configs/` (core defaults) loads before `UserConfigs/` (user overrides) for each concern — e.g. `configs.Startup_Apps` then `UserConfigs.Startup_Apps`. Put base behavior in `configs/`, override behavior in `UserConfigs/`.
- Startup apps are registered by appending to `ctx.autostart`; the `hyprland.start` hook in `hyprland.lua` executes them via `hl.exec_cmd`.
- Workspace keybinds are written explicitly with `hl.bind` + `hl.dsp.*` dispatchers (Hyprland 0.55's documented Lua form) — avoid legacy dispatcher strings.
- `hypr/dms/` holds DankMaterialShell integration (colors, layout, cursor, windowrules) shared between Hyprland and the shell.

### Shell layer

- `shell/` is a **vendored copy** (tracked directly in this repo, not a submodule) of upstream [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) (DMS), the primary top bar / desktop shell. Local edits under `shell/` diverge from upstream — treat carefully.
- Naming trap: the installer flag `--caelestia-shell` and the link target `~/.config/quickshell/caelestia` are **legacy names**; what actually lives there is DankMaterialShell, launched via `dms run --daemon`.
- `hypr/scripts/LaunchShell.sh` starts the shell: it prefers `dms`, and falls back to **Waybar** with a notification if `dms` is missing or times out. Any shell-startup change must preserve this fallback.
- `dms-plugins/` — DMS plugins (DockerLauncher, InstalI18n).
- `quickshell/` — a separate, simpler standalone Quickshell panel (`main.qml`, installed to `~/.config/quickshell/AdoRicing/`). Its convention: provider integrations (GitHub, Slack, Linear, mail, calendar) must be normalized into the shared app-panel and notification JSON shapes documented in `quickshell/README.md` before reaching QML — keep provider-specific logic out of the UI.

### Other components

- `terminal/` (kitty, starship, zsh, fastfetch), `rofi/`, `zed/`, `ado-sddm/` — per-app theme payloads copied/linked by the installer.
- `kwin/` and `kate/` are **legacy Plasma-era** components, kept for archival compatibility; they are not part of the Hyprland path.
- The install model is **symlink-based** (see `SYMLINK_MIGRATION_PLAN.md`, implemented): `install.sh` links repo files into place via the `link_file`/`link_dir` helpers, so the repo is the live source of truth. Rules that follow: never append to linked targets like `~/.zshrc` (machine-specific zsh goes in `~/.config/ado/zsh.local.zsh`); chmod scripts in the repo, not through the link; Zed `settings.json`/`keymap.json` are *generated* by merging committed `zed/*.shared.json` with git-ignored `zed/*.local.json` overlays — personal AI/model/tool preferences belong only in the local overlays.
- The Python scripts and PNGs at the repo root (`room_reconstruction_*`, `audit_*`, `render_*`, `create_*`, etc.) are a Blender room-reconstruction side project, unrelated to the theming suite.
