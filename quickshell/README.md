# Quickshell Panel

This directory contains the Quickshell panel config used by the Hyprland-first AdoRicing setup.

## Purpose

The panel provides:
- media title output
- Wi-Fi name
- volume
- battery
- clock

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
