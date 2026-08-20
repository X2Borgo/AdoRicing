# Instal i18n Health — DMS bar widget

DankMaterialShell bar widget showing Django translation health across every
checkout/worktree in `~/Desktop/Instal` that has gettext catalogs.

## What it shows

- **Bar pill**: Amaki logo + number of strings to fix (untranslated + fuzzy)
  counted on **main checkouts only** (feature worktrees carry duplicate
  catalogs). Red if anything is untranslated, yellow if only fuzzy, logo only
  when clean.
- **Popout** (click the pill): an "Instal tools" list — for now just the
  **Translations** card, showing main-checkout counts and data age, with:
  - **Refresh** — re-scans all worktrees (`scripts/refresh.sh`) and rebuilds
    the local dashboard.
  - **Open dashboard** — opens `~/.cache/instal-i18n/dashboard.html`, the full
    interactive report (worktree picker, per-language bars, string lists);
    built on the spot if missing.
  And the **Worktrees** card: overview of every linked git worktree across the
  workspace — total / cleanable / dirty counts and a per-worktree list
  (name · branch, state: broken / dirty / unpushed / merged·cleanable /
  PR open / no PR). **Refresh** re-scans local git state and PR state via `gh`
  (`scripts/worktrees.py`, cache `~/.cache/instal-tools/worktrees.json`).
  Read-only on purpose: a merged PR is not always disposable, so cleanup stays
  a deliberate action (see the `worktree-cleanup` Claude skill).
  More tool cards can slot in below these later.

## How it works

`scripts/collect_i18n.py` runs `msgfmt --statistics` and
`msgattrib --untranslated | --only-fuzzy | --only-obsolete` on every
`locale/*/LC_MESSAGES/*.po` and emits JSON to `~/.cache/instal-i18n/data.json`;
`build_dashboard.py` injects it into `dashboard_template.html`;
`summarize.py` prints the compact JSON the widget consumes.
Requires `gettext` (msgfmt/msgattrib), `python3`, `git`.

Workspace root defaults to `~/Desktop/Instal`; override with
`INSTAL_WORKSPACE`.

## Install

```sh
ln -s ~/Desktop/AdoRicing/dms-plugins/InstalI18n ~/.config/DankMaterialShell/plugins/instalI18n
dms ipc plugins reload
dms ipc plugins enable instalI18n
```

Then add `"instalI18n"` to a section in `barConfigs` (Settings → DankBar), or
directly in `~/.config/DankMaterialShell/settings.json`.
