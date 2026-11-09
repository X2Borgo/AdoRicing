#!/usr/bin/env python3
"""Collect Transloco translation health stats for an Angular checkout.

amaki's front end left Django's djangojs.po behind: the runtime catalogs are the
hand-maintained TS modules under
`frontend/price-ninja-angular/src/app/core/i18n/catalogs/<lang>.ts`, keyed by the
English source string, and the generator that used to write them from .po is gone.
Nothing regenerates or verifies them, so the gaps this reports are:

  untranslated  key present in en but missing (or empty) here, or — for a non-en
                catalog — copied verbatim from English
  fuzzy         (en only) an entry whose value differs from its key; legitimately
                only the handful of msgids whose source string is Italian
  obsolete      a catalog key no code references any more
  source gaps   a literal used in the code with no key in the en catalog — the
                failure that used to come from `make messages` reading the built
                bundle, reported as the `en/source` row

Usage: collect_transloco.py <catalogs_dir>   # .../core/i18n/catalogs
Emits the same file records collect_i18n.py emits for .po files.
"""
import json
import re
import sys
from pathlib import Path

# Keys are English sentences. A bare identifier-ish literal is far more likely a
# key of a *scoped* catalog (product/, landing/, …), which is a typed TS object
# checked by the compiler and not our business.
SCOPED_KEY = re.compile(r"^[a-z][A-Za-z0-9_]*$")

# One regex per quote character: a literal delimited by " may contain ' (and
# does — every English apostrophe in the catalog is written that way), so a
# single character class covering both quotes would cut those keys in half.
LITERAL = {q: r"{q}((?:[^{q}\\]|\\.)*?){q}".format(q=q) for q in "'\""}
USE_PATTERNS = [re.compile(pattern) for q in LITERAL for pattern in (
    rf"{LITERAL[q]}\s*\|\s*transloco",
    rf"(?:\.|\b)(?:translate|t)\(\s*{LITERAL[q]}",
)]


def read_catalog(path: Path) -> dict[str, str] | None:
    """Parse `export default { … } as const;` — the body is plain JSON."""
    text = path.read_text()
    marker = text.find("export default")
    if marker < 0:
        return None
    body = text[marker + len("export default"):]
    body = body.rsplit("as const", 1)[0].strip().rstrip(";").strip()
    try:
        value = json.loads(body)
    except ValueError:
        return None
    return value if isinstance(value, dict) else None


def unescape(literal: str) -> str:
    """Turn a source literal back into the string the catalog is keyed by."""
    # `\'` inside a single-quoted literal is just an apostrophe, and is not a
    # valid JSON escape — unescape it before handing the rest to the JSON parser.
    literal = literal.replace(r"\'", "'").replace('"', r'\"')
    try:
        return json.loads(f'"{literal}"')
    except ValueError:
        return literal


ANY_LITERAL = [re.compile(LITERAL[q]) for q in LITERAL]


def scan_sources(root: Path) -> tuple[dict[str, list[str]], set[str]]:
    """Translated literals with their `file:line` refs, and every literal seen.

    Two different questions need two different answers. "Is this key missing from
    the catalog?" is about call sites — `| transloco`, `translate(…)`, `t(…)`.
    "Is this key dead?" is not: plenty of live copy is written as a bare literal
    (`successMessage: 'Added to wishlist.'`) and only reaches Transloco several
    call frames later, so a key absent from the call sites is not thereby unused.
    Anything that appears as a literal anywhere in the app counts as referenced.
    """
    used: dict[str, list[str]] = {}
    seen: set[str] = set()
    # `src/` is the app; `projects/` is the amaki component library, whose copy
    # is translated from the very same catalogs.
    sources = [d for d in (root / "src", root / "projects") if d.is_dir()]
    for path in sorted(p for d in sources for p in d.rglob("*")):
        if path.suffix not in (".ts", ".html") or not path.is_file():
            continue
        if path.parent.name == "catalogs":
            continue
        if {"node_modules", "dist", ".angular"} & set(path.parts):
            continue
        for n, line in enumerate(path.read_text(errors="replace").splitlines(), 1):
            for pattern in ANY_LITERAL:
                seen.update(unescape(literal) for literal in pattern.findall(line))
            if path.name.endswith(".spec.ts"):
                continue
            for pattern in USE_PATTERNS:
                for literal in pattern.findall(line):
                    if "${" in literal:
                        continue
                    used.setdefault(unescape(literal), []).append(
                        f"{path.relative_to(root)}:{n}")
    return used, seen


def entry(msgid: str, msgstr: str = "", refs: list[str] | None = None) -> dict:
    return {"msgid": msgid, "msgstr": msgstr, "refs": refs or []}


def collect(catalogs_dir: Path) -> list[dict]:
    catalogs = {}
    for path in sorted(catalogs_dir.glob("*.ts")):
        if path.name.endswith(".spec.ts"):
            continue
        parsed = read_catalog(path)
        if parsed is not None:
            catalogs[path.stem] = parsed
    if "en" not in catalogs:
        return []

    english = catalogs["en"]
    # src/app/core/i18n/catalogs -> the Angular project root
    used, referenced = scan_sources(catalogs_dir.parents[4])

    files = []
    for lang, catalog in catalogs.items():
        untranslated, fuzzy, obsolete = [], [], []
        for key, source in english.items():
            value = catalog.get(key)
            if value is None:
                untranslated.append(entry(key, refs=used.get(key, [])))
            elif not value.strip():
                untranslated.append(entry(key, refs=used.get(key, [])))
            elif lang == "en":
                if value != key:
                    fuzzy.append(entry(key, value, used.get(key, [])))
            elif value == source:
                # Identical to the English string: either never translated or a
                # word that is genuinely the same in both. Fuzzy, not missing.
                fuzzy.append(entry(key, value, used.get(key, [])))
        for key, value in catalog.items():
            if key not in english:
                obsolete.append(entry(key, value))
            elif key not in referenced and lang == "en":
                obsolete.append(entry(key, value))
        translated = len(english) - len(untranslated) - len(fuzzy)
        files.append({
            "lang": lang,
            "domain": "catalog",
            "source": f"{lang}.ts",
            "translated": translated,
            "fuzzy": len(fuzzy),
            "untranslated": len(untranslated),
            "untranslated_entries": untranslated,
            "fuzzy_entries": fuzzy,
            "obsolete_entries": obsolete,
        })

    missing = [entry(key, refs=refs) for key, refs in sorted(used.items())
               if key not in english and not SCOPED_KEY.match(key)]
    files.append({
        "lang": "en",
        "domain": "source",
        "source": "src + projects",
        "translated": len(used) - len(missing),
        "fuzzy": 0,
        "untranslated": len(missing),
        "untranslated_entries": missing,
        "fuzzy_entries": [],
        "obsolete_entries": [],
    })
    return files


def main() -> None:
    print(json.dumps(collect(Path(sys.argv[1])), ensure_ascii=False, indent=1))


if __name__ == "__main__":
    main()
