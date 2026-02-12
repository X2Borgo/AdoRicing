#!/bin/bash

# KWin Script Installer for Ado Monitor Transparency
# This script installs and enables the transparency effect for secondary monitors

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.local/share/kwin/scripts/ado-monitor-transparency"

echo "═══════════════════════════════════════════════════"
echo "  Installing Ado Monitor Transparency KWin Script  "
echo "═══════════════════════════════════════════════════"
echo ""

# Create the directory if it doesn't exist
mkdir -p "$(dirname "$INSTALL_DIR")"

# Copy the script files
echo "→ Copying files to $INSTALL_DIR..."
cp -r "$SCRIPT_DIR" "$INSTALL_DIR"

# Enable the script
echo "→ Enabling the script..."
kwriteconfig6 --file kwinrc --group Plugins --key ado-monitor-transparencyEnabled true

# Reconfigure KWin to load the script
echo "→ Reloading KWin configuration..."
qdbus6 org.kde.KWin /KWin reconfigure

echo ""
echo "✓ Installation complete!"
echo ""
echo "═══════════════════════════════════════════════════"
echo "  Next Steps  "
echo "═══════════════════════════════════════════════════"
echo ""
echo "1. Test the installation:"
echo "   ./test.sh"
echo ""
echo "2. Open windows on your secondary monitor and observe:"
echo "   • Active window: 100% opacity"
echo "   • Inactive windows: 85% opacity (semi-transparent)"
echo "   • Primary monitor: Always 100% opacity"
echo ""
echo "═══════════════════════════════════════════════════"
echo "  Useful Commands  "
echo "═══════════════════════════════════════════════════"
echo ""
echo "View script logs in real-time:"
echo "  journalctl --user -f | grep AdoTransparency"
echo ""
echo "Disable the script:"
echo "  kwriteconfig6 --file kwinrc --group Plugins --key ado-monitor-transparencyEnabled false"
echo "  qdbus6 org.kde.KWin /KWin reconfigure"
echo ""
echo "Re-enable the script:"
echo "  kwriteconfig6 --file kwinrc --group Plugins --key ado-monitor-transparencyEnabled true"
echo "  qdbus6 org.kde.KWin /KWin reconfigure"
echo ""
echo "Uninstall:"
echo "  rm -rf $INSTALL_DIR"
echo "  kwriteconfig6 --file kwinrc --group Plugins --key ado-monitor-transparencyEnabled --delete"
echo "  qdbus6 org.kde.KWin /KWin reconfigure"
echo ""