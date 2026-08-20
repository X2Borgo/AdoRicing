#!/usr/bin/env python3
"""Overview of git worktrees across the Instal workspace.

Usage:
  worktrees.py collect   # scan workspace + query PR state, write cache, print JSON
  worktrees.py cached    # print cached JSON (collect if no cache yet)

Output: {"generated", "total", "cleanable", "dirty", "worktrees": [
  {"name", "repo", "branch", "dirty", "ahead", "upstream", "pr", "state"}]}

state: broken | dirty | unpushed | merged-clean (cleanable) | open-pr | no-pr
"""
import datetime
import json
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

WORKSPACE = Path(os.environ.get("INSTAL_WORKSPACE",
                                Path.home() / "Desktop" / "Instal"))
CACHE = Path(os.environ.get("XDG_CACHE_HOME",
                            Path.home() / ".cache")) / "instal-tools" / "worktrees.json"


def git(cwd: Path, *args: str) -> tuple[int, str]:
    r = subprocess.run(["git", "-C", str(cwd), *args],
                       capture_output=True, text=True, timeout=30)
    return r.returncode, r.stdout.strip()


def find_worktrees() -> list[Path]:
    """Linked worktrees at depth 1 (or 2, for nested layouts like
    price-ninja-css-fix/dev-479). Main checkouts (.git directory) are skipped."""
    found = []
    for d in sorted(WORKSPACE.iterdir()):
        if not d.is_dir() or d.name.startswith("."):
            continue
        candidates = [d]
        if not (d / ".git").exists():
            candidates = [c for c in sorted(d.iterdir())
                          if c.is_dir() and (c / ".git").exists()]
        for c in candidates:
            gitfile = c / ".git"
            # linked worktree = .git is a *file* pointing into <main>/.git/worktrees/
            if gitfile.is_file():
                found.append(c)
    return found


def gh_pr_state(repo: str, branch: str) -> str:
    try:
        r = subprocess.run(
            ["gh", "pr", "list", "--repo", f"Instal-srl/{repo}",
             "--head", branch, "--state", "all",
             "--json", "state", "--limit", "1"],
            capture_output=True, text=True, timeout=30)
        prs = json.loads(r.stdout) if r.returncode == 0 else []
        return prs[0]["state"].lower() if prs else "none"   # open|merged|closed
    except Exception:
        return "?"


def inspect(path: Path) -> dict:
    name = str(path.relative_to(WORKSPACE))
    code, _ = git(path, "rev-parse", "--git-dir")
    if code != 0:
        return {"name": name, "repo": "?", "branch": "?", "dirty": False,
                "ahead": 0, "upstream": False, "pr": "?", "state": "broken"}

    _, branch = git(path, "branch", "--show-current")
    branch = branch or "(detached)"
    _, origin = git(path, "remote", "get-url", "origin")
    repo = origin.rstrip("/").rsplit("/", 1)[-1].removesuffix(".git") if origin else "?"
    _, porcelain = git(path, "status", "--porcelain")
    dirty = bool(porcelain)
    up_code, ahead_out = git(path, "rev-list", "--count", "@{u}..HEAD")
    upstream = up_code == 0
    ahead = int(ahead_out) if upstream and ahead_out.isdigit() else 0

    pr = gh_pr_state(repo, branch) if repo != "?" else "?"

    if dirty:
        state = "dirty"
    elif (upstream and ahead > 0) or not upstream:
        state = "unpushed"
    elif pr == "merged":
        state = "merged-clean"
    elif pr == "open":
        state = "open-pr"
    else:
        state = "no-pr"
    return {"name": name, "repo": repo, "branch": branch, "dirty": dirty,
            "ahead": ahead, "upstream": upstream, "pr": pr, "state": state}


def collect() -> dict:
    paths = find_worktrees()
    with ThreadPoolExecutor(max_workers=8) as pool:
        worktrees = list(pool.map(inspect, paths))
    worktrees.sort(key=lambda w: (w["state"] != "broken", w["name"]))
    data = {
        "generated": datetime.datetime.now().strftime("%Y-%m-%d %H:%M"),
        "total": len(worktrees),
        "cleanable": sum(w["state"] == "merged-clean" for w in worktrees),
        "dirty": sum(w["state"] in ("dirty", "broken") for w in worktrees),
        "worktrees": worktrees,
    }
    CACHE.parent.mkdir(parents=True, exist_ok=True)
    tmp = CACHE.with_suffix(".tmp")
    tmp.write_text(json.dumps(data))
    tmp.rename(CACHE)
    return data


def main() -> None:
    mode = sys.argv[1] if len(sys.argv) > 1 else "cached"
    if mode == "cached" and CACHE.exists():
        print(CACHE.read_text())
        return
    print(json.dumps(collect()))


if __name__ == "__main__":
    main()
