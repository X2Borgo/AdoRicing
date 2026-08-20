#!/bin/bash

# KWin Script installer and lifecycle helper for Ado Monitor Transparency

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.local/share/kwin/scripts/ado-monitor-transparency"
PACKAGE_ID="ado-monitor-transparency"
ACTION="${1:-install}"

install_script() {
    echo "═══════════════════════════════════════════════════"
    echo "  Installing Ado Monitor Transparency KWin Script  "
    echo "═══════════════════════════════════════════════════"
    echo ""

    if command -v kpackagetool6 >/dev/null 2>&1; then
        echo "→ Installing KWin package with kpackagetool6..."
        kpackagetool6 --type KWin/Script --remove "$PACKAGE_ID" >/dev/null 2>&1 || true
        kpackagetool6 --type KWin/Script --install "$SCRIPT_DIR"
    else
        echo "→ kpackagetool6 not found, copying files to $INSTALL_DIR..."
        mkdir -p "$(dirname "$INSTALL_DIR")"
        rm -rf "$INSTALL_DIR"
        cp -r "$SCRIPT_DIR" "$INSTALL_DIR"
    fi

    echo "→ Enabling the script..."
    kwriteconfig6 --file kwinrc --group Plugins --key ado-monitor-transparencyEnabled true
    echo "→ Reloading KWin configuration..."
    qdbus6 org.kde.KWin /KWin reconfigure
    echo ""
    echo "✓ Installation complete"
}

disable_script() {
    echo "═══════════════════════════════════════════════════"
    echo "  Disabling Ado Monitor Transparency KWin Script   "
    echo "═══════════════════════════════════════════════════"
    echo ""
    kwriteconfig6 --file kwinrc --group Plugins --key ado-monitor-transparencyEnabled false
    echo "→ Reloading KWin configuration..."
    qdbus6 org.kde.KWin /KWin reconfigure
    echo ""
    echo "✓ Script disabled"
}

uninstall_script() {
    echo "═══════════════════════════════════════════════════"
    echo "  Removing Ado Monitor Transparency KWin Script    "
    echo "═══════════════════════════════════════════════════"
    echo ""

    if command -v kpackagetool6 >/dev/null 2>&1; then
        kpackagetool6 --type KWin/Script --remove "$PACKAGE_ID" >/dev/null 2>&1 || true
    fi

    rm -rf "$INSTALL_DIR"
    kwriteconfig6 --file kwinrc --group Plugins --key ado-monitor-transparencyEnabled --delete
    echo "→ Reloading KWin configuration..."
    qdbus6 org.kde.KWin /KWin reconfigure
    echo ""
    echo "✓ Script removed"
}

case "$ACTION" in
    install)
        install_script
        ;;
    disable|--disable)
        disable_script
        ;;
    uninstall|remove|--uninstall|--remove)
        uninstall_script
        ;;
    *)
        echo "Usage: $0 [install|--disable|--uninstall]"
        exit 1
        ;;
esac
