#!/bin/bash

# Debug script to show window opacity values in real-time
# This helps verify that the KWin transparency script is working

echo "=== Window Opacity Monitor ==="
echo "This script will show the opacity of all windows every 2 seconds"
echo "Press Ctrl+C to stop"
echo ""
echo "Expected behavior:"
echo "  - Primary monitor (eDP-1): All windows at 1.0 opacity"
echo "  - Secondary monitor (HDMI-A-1): Active window 1.0, inactive 0.85"
echo ""

while true; do
    clear
    echo "=== Window Opacity Status === $(date +%H:%M:%S)"
    echo ""
    
    # Get list of windows using wmctrl
    if command -v wmctrl >/dev/null 2>&1; then
        wmctrl -lG | while read -r line; do
            WIN_ID=$(echo "$line" | awk '{print $1}')
            X_POS=$(echo "$line" | awk '{print $3}')
            WIN_TITLE=$(echo "$line" | cut -d' ' -f8-)
            
            # Determine which monitor based on X position
            if [ "$X_POS" -lt 1920 ]; then
                MONITOR="PRIMARY  "
            else
                MONITOR="SECONDARY"
            fi
            
            # Try to get opacity using xprop
            OPACITY=$(xprop -id "$WIN_ID" _NET_WM_WINDOW_OPACITY 2>/dev/null | grep -oP '\d+$')
            if [ -n "$OPACITY" ]; then
                # Convert from 32-bit value to 0-1 range
                OPACITY_PERCENT=$(echo "scale=2; $OPACITY / 4294967295" | bc)
                printf "[$MONITOR] %s: %.2f\n" "$WIN_TITLE" "$OPACITY_PERCENT"
            else
                printf "[$MONITOR] %s: 1.00 (default)\n" "$WIN_TITLE"
            fi
        done
    else
        echo "wmctrl not installed. Install it with:"
        echo "  sudo apt install wmctrl"
        echo ""
        echo "Alternative: Check manually with xprop"
        echo "  1. Run: xprop | grep OPACITY"
        echo "  2. Click on a window"
        echo "  3. Look for _NET_WM_WINDOW_OPACITY value"
    fi
    
    echo ""
    echo "Active window:"
    xdotool getactivewindow getwindowname 2>/dev/null || echo "  (unknown)"
    
    echo ""
    echo "To manually test the script is loaded:"
    echo "  qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.loadedScripts"
    
    sleep 2
done