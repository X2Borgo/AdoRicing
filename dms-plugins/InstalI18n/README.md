# Instal i18n Health — DMS bar widget

DankMaterialShell bar widget showing translation health across every
checkout/worktree in `~/Projects/Instal` that carries a catalog — gettext `.po`
for the Django services, and the Transloco TS catalogs for amaki's front end.

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

`scripts/collect_i18n.py` walks the workspace and emits JSON to
`~/.cache/instal-i18n/data.json`. It reads two kinds of catalog and reports them
side by side under the same worktree:

- **gettext** — `msgfmt --statistics` and
  `msgattrib --untranslated | --only-fuzzy | --only-obsolete` on every
  `locale/*/LC_MESSAGES/*.po`.
- **Transloco** (`scripts/collect_transloco.py`) — amaki's front end left
  `djangojs.po` behind, along with the `po-to-catalogs.mjs` generator; its copy
  now lives in the hand-maintained `core/i18n/catalogs/<lang>.ts` modules, keyed
  by the English source string. Nothing regenerates or verifies them, so the
  collector does: it parses all five, takes `en` as the key set of record, and
  reports per language the keys missing from it (*untranslated*), the ones still
  identical to their English source (*fuzzy* — for `en` itself, the entries whose
  value differs from their key, legitimately only the Italian-source msgids), and
  the keys nothing in `src/` or `projects/` mentions any more (*obsolete*). One
  extra row, `en/source`, goes the other way: every literal the app translates
  (`| transloco`, `translate(…)`, `t(…)`) that no catalog has a key for. That row
  is the one that grows on its own, since adding a string no longer fails
  anything.

  Scoped catalogs (`landing/`, `product/`, `shared-chat/`, …) are deliberately
  skipped: they are typed TS objects, so a missing string there is a compile
  error rather than a silent gap.

`build_dashboard.py` injects it into `dashboard_template.html`;
`summarize.py` prints the compact JSON the widget consumes.
Requires `gettext` (msgfmt/msgattrib), `python3`, `git`.

Workspace root defaults to `~/Projects/Instal`; override with
`INSTAL_WORKSPACE`.

## Install

```sh
ln -s ~/Projects/ricing/AdoRicing/dms-plugins/InstalI18n ~/.config/DankMaterialShell/plugins/instalI18n
dms ipc plugins reload
dms ipc plugins enable instalI18n
```

Then add `"instalI18n"` to a section in `barConfigs` (Settings → DankBar), or
directly in `~/.config/DankMaterialShell/settings.json`.
