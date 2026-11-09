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

The shell launch log is written to `${XDG_RUNTIME_DIR:-/tmp}/shell-launch.log`; Noctalia's own log is `~/.cache/noctalia/noctalia.log`. Validate Noctalia config with `noctalia config validate noctalia` (read-only) and apply it with `noctalia msg config-reload` (no restart, windows untouched).

## Branching — this repo opts out of the global worktree rule

The working tree **is** the live desktop config: `~/.config/hypr`, `~/.zshrc`, and the kitty / rofi /
starship / zed payloads are symlinks into it. Checking out another branch rewrites the running
desktop's config source and live-breaks the Hyprland session. The global "implement in a fresh
worktree" rule does **not** apply here.

- Stay on `dev` for all local work — no worktrees, no branch switching.
- To sync `main`: `git fetch . dev:main` for the local ref, and a GitHub PR for the remote. `main`
  is protected: no direct pushes, squash-merge only.

## Editing here changes the running session

- `hypr/scripts/KittyAgentTabState.sh` is wired into `~/.claude/settings.json` as a hook on nine
  events (PreToolUse, PostToolUse, SessionStart, UserPromptSubmit, Stop, Subagent*, …). Editing it
  in this repo changes the hooks of **every running Claude Code session immediately** — a syntax
  error breaks them all at once. Run the script manually once after any edit to it.
- Reloading the compositor or restarting DMS closes every window, including the Claude Code
  sessions you are running in. Say so before doing it; never do it unprompted.
- Hyprland itself is updated by `~/Projects/ricing/Debian-Hyprland/update-hyprland.sh`, which lives outside
  this repo.
- Verification is visual and the user's. After a change, state what to look at and what "correct"
  should look like instead of declaring it fixed.

## Architecture

### hypr/ — Lua-based Hyprland config (installed to ~/.config/hypr)

Targets Hyprland 0.55+ and its **Lua API** (`hl.*`), not the classic hyprlang `.conf` format. The repo is mid-migration from `.conf` to `.lua`; deleted `.conf` files in git status reflect that. `hypr/hyprland.lua` is the entry point:

- It builds a shared global context `_G.ADO_HYPR` (`ctx.vars` for paths like `scriptsDir`, `ctx.autostart` for startup commands) and `require`s the module tree with a `require_once` guard.
- **Load order matters**: `configs/` (core defaults) loads before `UserConfigs/` (user overrides) for each concern — e.g. `configs.Startup_Apps` then `UserConfigs.Startup_Apps`. Put base behavior in `configs/`, override behavior in `UserConfigs/`.
- Startup apps are registered by appending to `ctx.autostart`; the `hyprland.start` hook in `hyprland.lua` executes them via `hl.exec_cmd`.
- Workspace keybinds are written explicitly with `hl.bind` + `hl.dsp.*` dispatchers (Hyprland 0.55's documented Lua form) — avoid legacy dispatcher strings.
- `hypr/dms/` holds DankMaterialShell integration (colors, layout, cursor, windowrules) shared between Hyprland and the shell.

### Shell layer

- **Noctalia v5** (native C++, from the `pkg.noctalia.dev` APT repo) is the primary shell. Its config is `noctalia/` (linked to `~/.config/noctalia` by `install.sh --noctalia`; every `*.toml` there is merged, GUI changes land in `~/.local/state/noctalia/settings.toml` and override it). The Ado palette is `noctalia/palettes/Ado.json`. Built-in color templates stay off: they append include lines to kitty/hyprland configs, which are symlinks into this repo.
- `noctalia-plugins/` holds our Luau plugins (ids `alborghi/*`), registered as the `ado` path source; community plugins are enabled by id in `[plugins].enabled`. Migration status: `docs/archive/NOCTALIA_MIGRATION_PLAN.md`.

- `shell/` (if present) is an untracked local DankMaterialShell clone and is gitignored; DMS itself comes from apt and is only the fallback shell. Noctalia is the live shell: `noctalia/` config, `noctalia-plugins/` Luau plugins (app-inbox fetchers in `noctalia-plugins/app-inbox/scripts/`).
- `hypr/scripts/LaunchShell.sh` starts the shell: it prefers `noctalia --daemon`, then `dms`, then **Waybar** + mako, notifying on each fallback. Any shell-startup change must preserve this chain.
- `dms-plugins/` — DMS plugins (DockerLauncher, InstalI18n); their Noctalia ports live in `noctalia-plugins/`, and InstalI18n's scripts are still called in place from here.
- `quickshell/` — a separate, simpler standalone Quickshell panel (`main.qml`, installed to `~/.config/quickshell/AdoRicing/`). Its convention: provider integrations (GitHub, Slack, Linear, mail, calendar) must be normalized into the shared app-panel and notification JSON shapes documented in `quickshell/README.md` before reaching QML — keep provider-specific logic out of the UI.

### Other components

- `terminal/` (kitty, starship, zsh, fastfetch), `rofi/`, `zed/`, `ado-sddm/` — per-app theme payloads copied/linked by the installer.
- `kwin/` and `kate/` are **legacy Plasma-era** components, kept for archival compatibility; they are not part of the Hyprland path.
- The install model is **symlink-based** (see `docs/archive/SYMLINK_MIGRATION_PLAN.md`, implemented): `install.sh` links repo files into place via the `link_file`/`link_dir` helpers, so the repo is the live source of truth. Rules that follow: never append to linked targets like `~/.zshrc` (machine-specific zsh goes in `~/.config/ado/zsh.local.zsh`); chmod scripts in the repo, not through the link; Zed `settings.json`/`keymap.json` are *generated* by merging committed `zed/*.shared.json` with git-ignored `zed/*.local.json` overlays — personal AI/model/tool preferences belong only in the local overlays.
- A Blender room-reconstruction side project used to live untracked at the repo root; it now resides at `~/Projects/personal/Room Reconstruction/` and is unrelated to this repo.
