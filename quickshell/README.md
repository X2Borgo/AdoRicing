# Quickshell Panel

This directory contains the Quickshell panel config used by the Hyprland-first AdoRicing setup.

## Purpose

The panel provides:
- media title output
- app status panels for GitHub, Slack, Linear, and calendar-style events
- a grouped notification drawer
- Wi-Fi name
- volume
- battery
- clock

## App Panels

`main.qml` currently ships with normalized mock app data at the top of the file. Keep provider-specific logic out of the UI: GitHub, Slack, Linear, mail, calendar, and other integrations should all produce the same app panel and notification shapes before they reach QML.

Panel shape:

```json
{ "key": "github", "name": "GitHub", "icon": "", "count": 4, "tone": "#c0c0c0", "detail": "2 reviews, 1 CI fail" }
```

Notification shape:

```json
{ "app": "GitHub", "icon": "", "title": "Review requested", "body": "AdoRicing PR #42 is waiting for your pass.", "time": "Now", "priority": "normal", "color": "#c0c0c0" }
```

Recommended adapter order:

1. GitHub via `gh api` for assigned issues, review requests, mentions, and failing checks.
2. Linear via its GraphQL API for assigned and urgent issues.
3. Slack via its Web API for DMs, mentions, and highlighted channels.
4. Calendar/mail/system updates once the drawer behavior is stable.

## Installation

The top-level installer copies the config to:

```bash
~/.config/quickshell/AdoRicing/main.qml
```

The repo does not install the `quickshell` binary itself. Install that separately for your distribution.

## Running

Run it manually with:

```bash
quickshell -p ~/.config/quickshell/AdoRicing/main.qml
```

For Hyprland autostart, add this to your Hyprland config:

```conf
exec-once = quickshell -p ~/.config/quickshell/AdoRicing/main.qml
```
