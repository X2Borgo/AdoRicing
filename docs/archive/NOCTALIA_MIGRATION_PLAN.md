# DMS → Noctalia v5 migration plan

Status: **steps 1–5 done on `dev` (uncommitted), awaiting visual check.** Decisions taken: Ado palette;
Noctalia replaces rofi launcher, clipboard, wlogout, hyprsunset, hypridle; extras = Claude Code meter,
GitHub PRs, k8s, window switcher, dock.

Done:
- `noctalia/config.toml` + `palettes/Ado.json`, linked to `~/.config/noctalia`; `install.sh --noctalia`.
- `LaunchShell.sh` (noctalia → dms → waybar), `Refresh*.sh`, `LockScreen.sh` (noctalia lock first, DMS + hyprlock kept), startup apps (hypridle, Hyprsunset, cliphist off), keybinds, layer/window rules, `rshell` alias.
- Plugins: ported `alborghi/docker-launcher`, `alborghi/instal-i18n`, `alborghi/app-inbox` (`noctalia-plugins/`); community claudecode, github-prs, k8s-status, tailscale, mini-docker, phone-connect.

Open:
- Keybind changes only apply after the next Hyprland reload/login (ALT+Tab was bound live).
- Fresh install: plugins listed in `[plugins].enabled` are not fetched by config alone — run `noctalia msg plugins enable <id>` once per community plugin.
- Wallpaper scripts (WallpaperSelect/Random, swww, wallust) still drive swww, which Noctalia's own wallpaper layer now covers — port to `noctalia msg wallpaper-set` or set `[wallpaper] enabled = false`.
- `icefish/phone-connect` upstream bug (`service.luau:437` calls `runCli` before definition; only the network-refresh nudge fails).
- gitmojiLauncher / dankGifSearch not ported.
- Idle CPU with full config ≈ 3.5–5.5 % of a core vs DMS 0.5 % — profile per widget.

## Measured load (idle)

| | DMS (`qs` + `dms` daemon, 2d22h uptime) | Noctalia 5.2.0 (fresh, defaults) |
|---|---|---|
| RSS | ~392 MB | ~204 MB |
| PSS | ~279 MB | ~112 MB |
| CPU | ~0.5 % of a core | ~3–5 % of a core (main thread; cause not yet found) |
| full config + 9 plugins, 41 min | | RSS 233 MB, PSS 134 MB, CPU ~3.5–5.5 % |

To re-measure once the real config is in place, and again after a few hours.

## Layout of the new config in the repo

- `noctalia/` (new) → linked to `~/.config/noctalia/` by `install.sh --noctalia`, split with `[include]`:
  `00-shell.toml`, `10-theme.toml`, `20-bar.toml`, `30-control-center.toml`, `40-notifications-osd.toml`,
  `50-lock-idle.toml`, `60-launcher.toml`, `70-plugins.toml`, `palettes/`, `templates/`.
- GUI changes land in `~/.local/state/noctalia/settings.toml` (not in the repo); fold good ones back into the TOML.
- `noctalia-plugins/` (new) → registered as a `path` plugin source: our own Luau plugins.

## Feature map

| DMS today | Noctalia | Work |
|---|---|---|
| Autostart via `LaunchShell.sh` (`dms run --daemon`, waybar+mako fallback) | `noctalia --daemon` | Rewrite `LaunchShell.sh`: prefer noctalia → dms → waybar. Log to `$XDG_RUNTIME_DIR/noctalia-launch.log` |
| `Refresh.sh` / `RefreshNoWaybar.sh` (`dms kill`/`restart`) | restart noctalia, or `noctalia msg config-reload` | Update both scripts and the `rdms` zsh alias |
| Bar left: launcher, workspaces (index shown), focused window | `launcher`, `workspaces` (`label_source="id"`), `active_window` | Config |
| Bar center: music, clock 24h, weather, **appInbox** | `media`, `clock` `{:%H:%M}`, `weather` + `[location]`, **custom plugin** | Config + port (see below) |
| Bar right: slackSidebar, tray, KDEConnect, clipboard, cpu, mem, instalI18n, notifications, battery, control center | (Slack: part of inbox port), `tray`, `phone-connect` (community), `clipboard`, `sysmon` cpu_usage + ram_used, **InstalI18n port**, `notifications`, `battery`, `control-center` | Config + port |
| Control center tiles: volume, brightness, wifi, bt, audio out/in, night, dark mode, idle inhibit, battery, KDEConnect, tailscale | `audio`, `mic_mute`, `wifi`, `bluetooth`, `nightlight`, `dark_mode`, `caffeine`, `power_profile`, `system`, + `tailscale` community plugin | Config |
| Notifications (DMS owns the daemon), `SUPER+SHIFT+N` | built-in daemon, `panel-toggle control-center notifications`-style toggle | Keybind + config |
| Lock: `LockScreen.sh` → `dms ipc call lock …`, hyprlock fallback, `--stealth` | `noctalia msg session lock`, + `dpms-off` for stealth | Rewrite DMS branch of `LockScreen.sh`, keep hyprlock fallback |
| hypridle → `LockScreen.sh --logind-hook` | keep hypridle (works unchanged via `LockScreen.sh`) **or** Noctalia `[idle]` | Decision |
| Theme: Catppuccin Mocha (blue accent) registry theme | builtin `Catppuccin` **or** custom Ado palette **or** wallpaper | Decision |
| Wallpaper: `merry_wallpaper.png` via DMS session; swww/wallust scripts | Noctalia `[wallpaper]` (it draws its own) | Point `[wallpaper.default] path`; wallpaper scripts → `noctalia msg wallpaper-set` instead of swww |
| Corner radius 12, gaps 4, border 2 | `corner_radius_scale`, bar `radius` | Config |
| Cursor `AdoCursorTheme` 26 (`hypr/dms/cursor.lua`) | not a shell concern | Move to `hypr/configs/` so it stops depending on `hypr/dms/` |
| `hypr/dms/{colors,layout,windowrules}.lua` | — | Already unused; delete. Add noctalia layer rules (blur, no_anim) + float rule for `dev.noctalia.Noctalia` |
| Plugins: dockerLauncher (ours), dockerManager | community `mini-docker` + port **DockerLauncher** as a launcher provider wrapping `DockerMenu.sh` | Port (small) |
| InstalI18n (ours, bar pill + popout) | Luau bar widget + panel, reusing `scripts/*.sh`/`*.py` untouched | Port (medium) |
| **AppInbox** (ours: GitHub, Slack, Gmail, Linear, Calendar, Deployments; 796-line popout + 6 services) | Luau service + bar widget + panel, reusing the Python fetchers in `shell/quickshell/scripts/` | Port (large) — also fixes the `SUPER+SHIFT+D` `app-inbox` IPC that the vendored DMS no longer answers |
| dankKDEConnect | community `phone-connect` | Enable, check it talks to kdeconnectd |
| tailscale | community `tailscale` / `tailnet` | Enable |
| gitmojiLauncher, dankGifSearch, dankLauncherKeys | no equivalent | Port gitmoji (tiny launcher provider); GIF search optional; launcherKeys is DMS-specific, drop |
| Notepad module | official `notes` / community `sticky-notes` | Enable |
| Rofi launcher (SUPER+D), wlogout (CTRL+ALT+P), Hyprsunset (SUPER+N), cliphist (ClipManager.sh) | Noctalia launcher, `session` panel, `nightlight`, encrypted clipboard history | Decision: keep rofi/wlogout/etc. or switch |

## "And more" — candidates worth adding

- `github-prs` (PRs + CI/review state via `gh`) — may overlap the inbox port
- `claude-cockpit` / `claudecode` (Claude Code sessions + rate limits) — fits the kitty agent-tab work
- `keybind-cheatsheet` (searchable Hyprland binds) — could replace `KeyHints.sh`
- `k8s-status` (`/kube`) — you use kubectl daily
- official `translator`, `screen_recorder`, `timer`; community `ocr`, `color_picker`, `pomodoro`
- built-in: window switcher (`ALT+Tab`), screenshot + annotate, hot corners, desktop widgets, dock

## Order of work (each step reversible: DMS stays installed as fallback)

1. Repo skeleton `noctalia/`, `install.sh --noctalia`, link `~/.config/noctalia`.
2. Theme + bar + control center + notifications/OSD config (visual check by you).
3. `LaunchShell.sh`, `Refresh*.sh`, zsh alias, Hyprland layer/window rules, keybinds.
4. Lock/idle.
5. Plugins: DockerLauncher → InstalI18n → AppInbox (+ enable community ones).
6. Re-measure CPU/RAM; chase the main-thread CPU.
7. Docs: CLAUDE.md / README (shell section), mark `shell/` as DMS fallback/legacy.
