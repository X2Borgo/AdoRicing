#!/usr/bin/env python3
"""Build the self-contained dashboard HTML from data.json + template.

Usage: build_dashboard.py <data.json> <output.html>
"""
import datetime
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent


def main() -> None:
    data_path, out_path = Path(sys.argv[1]), Path(sys.argv[2])
    data = data_path.read_text().replace("</", r"<\/")
    html = (HERE / "dashboard_template.html").read_text()
    html = html.replace("__DATA__", data)
    html = html.replace("__GENERATED__", datetime.date.today().isoformat())
    out_path.write_text(
        '<!doctype html>\n<meta charset="utf-8">\n'
        '<meta name="viewport" content="width=device-width, initial-scale=1">\n'
        + html
    )


if __name__ == "__main__":
    main()
