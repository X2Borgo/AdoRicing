#!/bin/bash

# Visual Demo Script for Ado Monitor Transparency
# This script helps you visually test if the transparency effect is working

echo "═══════════════════════════════════════════════════"
echo "  Ado Monitor Transparency - Visual Demo"
echo "═══════════════════════════════════════════════════"
echo ""
echo "This demo will help you test if the transparency"
echo "effect is working on your secondary monitor."
echo ""

# Check if script is loaded
LOADED=$(qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.isScriptLoaded "ado-monitor-transparency" 2>/dev/null)
if [ "$LOADED" != "true" ]; then
    echo "✗ Error: Script is not loaded!"
    echo "  Run: cd AdoRicing/kwin && ./install.sh"
    exit 1
fi

echo "✓ Script is loaded and active"
echo ""
echo "═══════════════════════════════════════════════════"
echo "  Testing Instructions"
echo "═══════════════════════════════════════════════════"
echo ""
echo "1. SETUP:"
echo "   • Make sure you have a secondary monitor connected"
echo "   • Open 2-3 windows (Kate, Kitty, Dolphin, etc.)"
echo "   • Drag at least one window to your secondary monitor"
echo ""
echo "2. TEST THE EFFECT:"
echo "   • Click on a window on your PRIMARY monitor"
echo "     → All windows on secondary should become semi-transparent"
echo ""
echo "   • Click on a window on your SECONDARY monitor"
echo "     → That window should become fully opaque"
echo "     → Other windows on secondary stay semi-transparent"
echo ""
echo "3. WHAT YOU SHOULD SEE:"
echo "   • Primary monitor windows: Always 100% opaque"
echo "   • Secondary monitor active window: 100% opaque"
echo "   • Secondary monitor inactive windows: 85% opaque (subtle)"
echo ""
echo "4. TROUBLESHOOTING:"
echo "   If you don't see any effect:"
echo "   • The transparency is subtle (85% vs 100%)"
echo "   • Try with windows that have solid backgrounds"
echo "   • Check compositor is enabled:"
echo "     System Settings → Display → Compositor"
echo "   • Check logs:"
echo "     journalctl --user -n 50 | grep kwin"
echo ""
echo "═══════════════════════════════════════════════════"
echo "  Test Applications"
echo "═══════════════════════════════════════════════════"
echo ""
echo "Good apps to test with (solid backgrounds):"
echo "  • Kate (text editor)"
echo "  • Kitty (terminal)"
echo "  • Dolphin (file manager)"
echo "  • System Settings"
echo ""
echo "Press Enter to open test windows..."
read -r

# Try to open some test windows
echo "Opening test windows..."

if command -v kate >/dev/null 2>&1; then
    echo "→ Opening Kate..."
    kate /tmp/transparency-test-1.txt >/dev/null 2>&1 &
    sleep 1
fi

if command -v kitty >/dev/null 2>&1; then
    echo "→ Opening Kitty..."
    kitty -e bash -c 'echo "Window 1 - Drag me to secondary monitor"; echo "Click between windows to test transparency"; bash' >/dev/null 2>&1 &
    sleep 1
fi

if command -v dolphin >/dev/null 2>&1; then
    echo "→ Opening Dolphin..."
    dolphin ~ >/dev/null 2>&1 &
    sleep 1
fi

echo ""
echo "✓ Test windows opened"
echo ""
echo "═══════════════════════════════════════════════════"
echo "  Now test the effect!"
echo "═══════════════════════════════════════════════════"
echo ""
echo "1. Drag one or more windows to your SECONDARY monitor"
echo "2. Click between different windows"
echo "3. Watch inactive windows on secondary monitor fade"
echo ""
echo "The effect is subtle by design (15% transparency)."
echo "To make it more obvious, edit:"
echo "  AdoRicing/kwin/contents/code/main.js"
echo "  Change: const TRANSPARENCY_LEVEL = 0.85;"
echo "  To:     const TRANSPARENCY_LEVEL = 0.60;"
echo "  Then run: ./install.sh"
echo ""
echo "Press Ctrl+C to exit this script (windows will remain open)"
echo ""

# Keep script running so user can read instructions
while true; do
    sleep 1
done