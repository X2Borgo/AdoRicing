#!/usr/bin/env python3
"""Collect Django translation health stats into JSON.

Usage:
  collect_i18n.py <workspace_root>   # scan every checkout/worktree with .po catalogs
Runs msgfmt --statistics and msgattrib per .po file.
"""
import json
import re
import subprocess
import sys
from pathlib import Path


def msgfmt_stats(po: Path) -> dict:
    out = subprocess.run(
        ["msgfmt", "--statistics", "-o", "/dev/null", str(po)],
        capture_output=True, text=True,
    ).stderr
    stats = {"translated": 0, "fuzzy": 0, "untranslated": 0}
    for n, kind in re.findall(r"(\d+) (translated|fuzzy|untranslated)", out):
        stats[kind] = int(n)
    return stats


def msgattrib_entries(po: Path, *flags: str) -> list[dict]:
    """Return [{msgid, msgstr, refs}] for entries matching the msgattrib flags."""
    out = subprocess.run(
        ["msgattrib", *flags, str(po)], capture_output=True, text=True
    ).stdout
    entries = []
    # Split into blocks; skip the header (msgid "")
    for block in out.split("\n\n"):
        lines = block.strip("\n").splitlines()
        if not lines:
            continue
        refs, msgid, msgstr, target = [], [], [], None
        for line in lines:
            if line.startswith("#~"):
                line = line[2:].strip()
            if line.startswith("#:"):
                refs.extend(line[2:].split())
                continue
            if line.startswith("#"):
                continue
            if line.startswith("msgid "):
                target = msgid
                line = line[len("msgid "):]
            elif line.startswith("msgstr"):
                target = msgstr
                line = line.split(" ", 1)[1] if " " in line else '""'
            if target is not None and line.startswith('"'):
                target.append(json.loads(line))
        mid = "".join(msgid)
        if not mid:  # header
            continue
        entries.append({"msgid": mid, "msgstr": "".join(msgstr), "refs": refs})
    return entries


def git(root: Path, *args: str) -> str:
    r = subprocess.run(["git", "-C", str(root), *args], capture_output=True, text=True)
    return r.stdout.strip()


def collect_locale_dir(locale_dir: Path) -> tuple[list[dict], str]:
    files = []
    pot_date = ""
    for po in sorted(locale_dir.glob("*/LC_MESSAGES/*.po")):
        lang = po.parts[-3]
        stats = msgfmt_stats(po)
        files.append({
            "lang": lang,
            "domain": po.stem,
            **stats,
            "untranslated_entries": msgattrib_entries(po, "--untranslated", "--no-obsolete"),
            "fuzzy_entries": msgattrib_entries(po, "--only-fuzzy", "--no-obsolete"),
            "obsolete_entries": msgattrib_entries(po, "--only-obsolete"),
        })
        if not pot_date:
            m = re.search(r"POT-Creation-Date: (.+?)\\n", po.read_text())
            if m:
                pot_date = m.group(1)
    return files, pot_date


def main() -> None:
    workspace = Path(sys.argv[1])
    # A checkout owns all LC_MESSAGES dirs under it; group locale dirs by
    # the git toplevel that contains them.
    locale_dirs = sorted(
        {p.parent.parent for p in workspace.glob("*/**/LC_MESSAGES")
         if p.is_dir()
         and "node_modules" not in p.parts and ".venv" not in p.parts}
    )
    worktrees = []
    for locale_dir in locale_dirs:
        toplevel = git(locale_dir, "rev-parse", "--show-toplevel")
        # Broken worktrees (pruned metadata) make git fail: fall back to the
        # checkout dir, i.e. the first path component under the workspace.
        root = Path(toplevel) if toplevel else (
            workspace / locale_dir.relative_to(workspace).parts[0])
        repo = git(root, "remote", "get-url", "origin").rstrip("/")
        repo = repo.rsplit("/", 1)[-1].removesuffix(".git") if repo else "?"
        branch = git(root, "branch", "--show-current") or git(
            root, "rev-parse", "--short", "HEAD") or "broken worktree"
        files, pot_date = collect_locale_dir(locale_dir)
        if not files:
            continue
        worktrees.append({
            "name": str(root.relative_to(workspace)) if root.is_relative_to(workspace) else root.name,
            "repo": repo,
            "branch": branch,
            "locale_dir": str(locale_dir.relative_to(root)),
            "pot_date": pot_date,
            "files": files,
        })
    print(json.dumps({"workspace": str(workspace), "worktrees": worktrees},
                     ensure_ascii=False, indent=1))


if __name__ == "__main__":
    main()
