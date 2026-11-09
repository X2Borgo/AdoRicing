#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "icalendar>=6.1,<7",
#   "recurring-ical-events>=3.5,<4",
# ]
# ///

import json
import sys
import urllib.request
from datetime import date, datetime, time, timedelta

from icalendar import Calendar
import recurring_ical_events


def as_datetime(value, fallback_tz):
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=fallback_tz)
    if isinstance(value, date):
        return datetime.combine(value, time.min, tzinfo=fallback_tz)
    raise ValueError("Unsupported calendar date")


def text(component, key):
    value = component.get(key)
    return str(value) if value is not None else ""


def main():
    if len(sys.argv) != 2:
        raise SystemExit("usage: google_calendar_feed.py URL_FILE")

    with open(sys.argv[1], encoding="utf-8") as handle:
        feed_url = handle.read().strip()
    if not feed_url.startswith("https://"):
        raise ValueError("Calendar URL must use HTTPS")

    request = urllib.request.Request(feed_url, headers={"User-Agent": "DMS-App-Inbox/1.0"})
    with urllib.request.urlopen(request, timeout=18) as response:
        calendar = Calendar.from_ical(response.read())

    now = datetime.now().astimezone()
    window_start = now - timedelta(days=1)
    window_end = now + timedelta(days=30)
    rows = []

    for event in recurring_ical_events.of(calendar).between(window_start, window_end):
        start_value = event.decoded("DTSTART")
        end_property = event.get("DTEND")
        end_value = event.decoded("DTEND") if end_property is not None else start_value
        all_day = isinstance(start_value, date) and not isinstance(start_value, datetime)
        start = as_datetime(start_value, now.tzinfo)
        end = as_datetime(end_value, now.tzinfo)
        rows.append({
            "id": text(event, "UID") + "-" + start.isoformat(),
            "title": text(event, "SUMMARY") or "Untitled event",
            "description": text(event, "DESCRIPTION"),
            "location": text(event, "LOCATION"),
            "url": text(event, "URL") or "https://calendar.google.com/calendar/u/0/r",
            "start": start.isoformat(),
            "end": end.isoformat(),
            "allDay": all_day,
        })

    rows.sort(key=lambda item: item["start"])
    print(json.dumps({"events": rows}, ensure_ascii=False))


if __name__ == "__main__":
    main()
