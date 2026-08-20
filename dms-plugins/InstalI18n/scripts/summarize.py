#!/usr/bin/env python3
"""Print a compact summary of data.json for the bar widget.

Usage: summarize.py <data.json>
Output: {"generated", "untranslated", "fuzzy", "obsolete", "worktrees": [...]}
"""
import datetime
import json
import sys
from pathlib import Path


def main() -> None:
    data_path = Path(sys.argv[1])
    d = json.loads(data_path.read_text())
    worktrees = []
    tot = {"untranslated": 0, "fuzzy": 0, "obsolete": 0}
    for w in d["worktrees"]:
        untr = sum(f["untranslated"] for f in w["files"])
        fuzzy = sum(f["fuzzy"] for f in w["files"])
        dead = sum(len(f["obsolete_entries"]) for f in w["files"])
        tot["untranslated"] += untr
        tot["fuzzy"] += fuzzy
        tot["obsolete"] += dead
        worktrees.append({
            "name": w["name"], "repo": w["repo"], "branch": w["branch"],
            "untranslated": untr, "fuzzy": fuzzy, "obsolete": dead,
        })
    generated = datetime.datetime.fromtimestamp(
        data_path.stat().st_mtime).strftime("%Y-%m-%d %H:%M")
    print(json.dumps({"generated": generated, **tot, "worktrees": worktrees}))


if __name__ == "__main__":
    main()
