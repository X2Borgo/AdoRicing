# Symlink Migration Plan

> **Status (2026-08-20): implemented.** `install.sh` now links all repo-owned config
> (hypr, kitty, starship, zsh, fastfetch, rofi, kate theme, quickshell panel, shell
> tree, zed theme), Zed settings/keymap are generated from `*.shared.json` +
> git-ignored `*.local.json` overlays, `.zshrc` sources `~/.config/ado/zsh.local.zsh`
> instead of being appended to, and Floorp/Epiphany remnants are gone. Kept for the
> rationale below; the live behavior in `install.sh` wins on any disagreement.

## Goal

Move the installer from copying live configuration files into linking repo-owned configuration files. After this migration, the repository should be the source of truth for general configuration, while personal or machine-specific settings stay outside git.

## Current State

- Most components are copied by `install.sh`.
- `shell/` is already symlinked into `~/.config/quickshell/caelestia`.
- The repo contains a local live-state symlink, `applications -> ~/.local/share/applications`; it is ignored and should not become part of the install model.
- Zed currently mixes general editor defaults with personal agent/model/tool preferences in one committed `zed/settings.json`.
- Browser support currently includes Floorp and Epiphany, but the target browser setup is now Zen as primary and Chrome as fallback.

## Installer Foundation

Add small installer helpers before changing component behavior:

- `backup_path TARGET`: backs up files, directories, and unmanaged symlinks.
- `ensure_parent TARGET`: creates the parent directory for a file target.
- `link_file SOURCE TARGET`: backs up an incompatible target, then creates a stable symlink.
- `link_dir SOURCE TARGET`: backs up an incompatible directory or symlink, then links the full directory.
- `is_managed_link SOURCE TARGET`: avoids noisy backups when the correct symlink already exists.

The installer should still install packages, set defaults, refresh desktop databases, and generate files where generation is genuinely required.

## Migrate To Symlinks

These files and directories should be linked directly because they are repo-owned general configuration:

| Repo path | Live target |
| --- | --- |
| `hypr/` | `~/.config/hypr` |
| `terminal/kitty/kitty.conf` | `~/.config/kitty/kitty.conf` |
| `terminal/starship/starship.toml` | `~/.config/starship.toml` |
| `terminal/fastfetch/ado.jsonc` | `~/.config/fastfetch/ado.jsonc` |
| `terminal/fastfetch/ado.png` | `~/.config/fastfetch/ado.png` |
| `terminal/zsh/.zshrc` | `~/.zshrc` |
| `rofi/config.rasi` | `~/.config/rofi/config.rasi` |
| `rofi/ado.rasi` | `~/.config/rofi/ado.rasi` |
| `quickshell/main.qml` | `~/.config/quickshell/AdoRicing/main.qml` |
| `useful_images/Ado-Rose.svg` | `~/.config/quickshell/AdoRicing/Ado-Rose.svg` |
| `kate/Ado-Hibana.theme` | `~/.local/share/org.kde.syntax-highlighting/themes/Ado-Hibana.theme` |
| `shell/` | `~/.config/quickshell/caelestia` |

After linking `hypr/`, the installer should still ensure executable bits are correct for scripts in the repository. Do not chmod copied targets after the target becomes a symlinked tree.

## Zed Split

Zed needs a split before symlink migration because personal and general configuration are currently mixed.

Committed general configuration:

- `zed/Ado-Hibana.json`
- `zed/settings.shared.json`
- `zed/keymap.shared.json`

Ignored personal configuration:

- `zed/settings.local.json`
- `zed/keymap.local.json`

Move these out of committed shared settings:

- AI agent provider/model choices.
- Tool auto-approval preferences.
- Commit-message model preferences.
- Trusted worktree/session preferences.
- Machine-specific language server choices.
- Any account, auth, or provider-specific preferences.

Installer behavior:

- Link `zed/Ado-Hibana.json` to `~/.config/zed/themes/Ado-Hibana.json`.
- Do not blindly symlink the current `zed/settings.json`.
- Either generate `~/.config/zed/settings.json` from shared plus ignored local overlay, or verify and use Zed's native import/include behavior if available.
- Treat keymap the same way: shared defaults can be committed, private local overrides must stay ignored.

## Shell Split

The installer currently appends Starship and Fastfetch blocks into `~/.zshrc`. That is incompatible with making `.zshrc` a symlink.

Migration steps:

- Put the Starship and Fastfetch initialization directly in `terminal/zsh/.zshrc`.
- Add an optional local include such as `~/.config/ado/zsh.local.zsh`.
- Ignore any repo-side local shell overlay files, for example `terminal/zsh/*.local.zsh`.
- Change the installer to link `terminal/zsh/.zshrc` to `~/.zshrc` and stop appending to it.

## Browser Direction

Remove Floorp and Epiphany from the target install plan.

Target browser setup:

- Zen is the primary browser.
- Chrome is the fallback browser.
- Other browser install/configuration paths should be removed from the installer and docs.

Actions:

- Remove `--floorp` and `--epiphany` options from `install.sh`.
- Remove Floorp and Epiphany from the default `--hyprland` install set.
- Remove Floorp and Epiphany from `--all`, unless a deliberate legacy option is kept.
- Remove Floorp/Epiphany README sections and project-structure entries.
- Remove or archive `floorp/` and `epiphany/` after confirming there is no desired Zen/Chrome reusable config inside them.
- Review Hyprland browser keybinds and launcher scripts:
  - `hypr/scripts/LaunchBrowser.sh`
  - any keybinds that launch Floorp or Epiphany
  - desktop entries generated into `~/.local/share/applications`
- Add Zen launcher/default-browser handling if needed.
- Keep Chrome as fallback without treating Chrome profile contents as repo-owned config.

Do not symlink browser profile internals in this migration. Browser profiles are mutable runtime state and should not be committed.

## Keep Generated Or Imperative

These should not become simple symlinks:

- Font installation and font cache refresh.
- Package installation.
- Oh My Zsh installation.
- `chsh`.
- `xdg-settings`.
- `gsettings`.
- `update-desktop-database`.
- SDDM config under `/etc/sddm.conf.d/`.
- Any desktop entry that needs machine-specific path substitution.
- Browser profile files and runtime profile directories.

## Gitignore Updates

Add ignore rules for private overlays:

```gitignore
zed/settings.local.json
zed/keymap.local.json
terminal/zsh/*.local.zsh
```

If Hyprland local override support is added later, also ignore a narrow local pattern such as:

```gitignore
hypr/UserConfigs/*.local.lua
```

Do not broaden ignores in a way that hides committed dotfiles like `terminal/zsh/.zshrc`.

## Documentation Updates

Update `README.md` after the installer migration:

- State that general config is live-linked from the repository.
- Explain that editing repo files updates live config.
- Document private local overlays for Zed and ZSH.
- Remove Floorp and Epiphany from the current stack, quick install, selective install, browser notes, and project structure.
- Add Zen as primary browser and Chrome as fallback.
- Clarify which installer steps still generate files instead of symlinking them.

## Validation

After implementation:

- Run `bash -n install.sh`.
- Test selected installer paths with a temporary `HOME` where possible.
- Verify symlink targets with `readlink`.
- Confirm no private Zed or shell overlay files show up in `git status`.
- Confirm generated desktop entries do not reference removed browser scripts.
- Confirm Hyprland browser keybinds launch Zen first and Chrome as fallback where intended.

## Suggested Implementation Order

1. Add installer symlink helper functions.
2. Remove Floorp and Epiphany installer options and docs references.
3. Split Zed shared/private configuration.
4. Split ZSH shared/private configuration and remove installer appends.
5. Convert low-risk copied configs to symlinks: Kitty, Starship, Fastfetch, Rofi, Kate, Quickshell.
6. Convert `hypr/` to a directory symlink.
7. Review Zen/Chrome launcher behavior and keybinds.
8. Update README and `.gitignore`.
9. Run validation.
