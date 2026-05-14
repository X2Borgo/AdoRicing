---@diagnostic disable: undefined-global
---@type HL.API
local hl = hl
local ctx = rawget(_G, "ADO_HYPR") or { vars = {}, autostart = {}, loaded = {} }
_G.ADO_HYPR = ctx
local vars = ctx.vars
local function home()
  return os.getenv("HOME") or ""
end
local function require_once(module)
  if not ctx.loaded[module] then
    ctx.loaded[module] = true
    require(module)
  end
end

local function keybind(keys, dispatcher, opts)
  local tokens = {}
  for token in tostring(keys):gsub("%s*%+%s*", " "):gmatch("%S+") do
    tokens[#tokens + 1] = token
  end
  return hl.bind(table.concat(tokens, " + "), dispatcher, opts)
end

-- Converted from configs/Keybinds.conf
-- /* ---- 💫 https://github.com/LinuxBeginnings 💫 ---- */  #
-- Default Keybinds
-- visit https://wiki.hyprland.org/Configuring/Binds/ for more info
-- /* ---- ✴️ Variables ✴️ ---- */  #
vars["mainMod"] = "SUPER"
vars["scriptsDir"] = home() .. "/.config/hypr/scripts"
vars["UserConfigs"] = home() .. "/.config/hypr/UserConfigs"
vars["UserScripts"] = home() .. "/.config/hypr/UserScripts"
-- settings for User defaults apps - set your default terminal and file manager on this file
-- source = $UserConfigs/01-UserDefaults.conf
require_once("UserConfigs.01-UserDefaults")
-- ### STANDAR ####
-- Common shortcuts
-- bindr = $mainMod, $mainMod_L, exec, pkill rofi || rofi -show drun -modi drun,filebrowser,run,window # Super Key to Launch rofi menu
keybind((vars["mainMod"] or "") .. " + D", hl.dsp.exec_cmd("pkill rofi || true && rofi -show drun -modi drun,filebrowser,run,window"), { desc = "app launcher" })
keybind((vars["mainMod"] or "") .. " + B", hl.dsp.exec_cmd("xdg-open \"https://\""), { desc = "open default browser" })
keybind((vars["mainMod"] or "") .. " + A", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/OverviewToggle.sh"), { desc = "desktop overview" })
-- bindd = $mainMod, A, ags overview, exec, pkill rofi || true && ags -t 'overview' # desktop overview (if installed)
-- bindd = $mainMod, A, Quickshell overview, global, quickshell:overviewToggle # desktop overview (if installed)
keybind((vars["mainMod"] or "") .. " + Return", hl.dsp.exec_cmd((vars["term"] or "")), { desc = "Open terminal" })
keybind((vars["mainMod"] or "") .. " + E", hl.dsp.exec_cmd((vars["files"] or "")), { desc = "file manager" })
-- FEATURES / EXTRAS
keybind((vars["mainMod"] or "") .. " + T", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/ThemeChanger.sh"), { desc = "Global theme switcher using Wallust" })
keybind((vars["mainMod"] or "") .. " + H", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/KeyHints.sh"), { desc = "help / cheat sheet" })
keybind((vars["mainMod"] or "") .. " ALT + R", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/Refresh.sh"), { desc = "refresh bar and menus" })
keybind((vars["mainMod"] or "") .. " ALT + E", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/RofiEmoji.sh"), { desc = "emoji menu" })
keybind((vars["mainMod"] or "") .. " + S", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/RofiSearch.sh"), { desc = "web search" })
keybind((vars["mainMod"] or "") .. " CTRL + S", hl.dsp.exec_cmd("rofi -show window"), { desc = "window switcher" })
keybind((vars["mainMod"] or "") .. " ALT + O", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/ChangeBlur.sh"), { desc = "toggle blur" })
keybind((vars["mainMod"] or "") .. " SHIFT + G", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/GameMode.sh"), { desc = "toggle game mode" })
keybind((vars["mainMod"] or "") .. " ALT + L", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/ChangeLayout.sh"), { desc = "toggle master/dwindle layout" })
keybind((vars["mainMod"] or "") .. " ALT + V", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/ClipManager.sh"), { desc = "clipboard manager" })
keybind((vars["mainMod"] or "") .. " CTRL + R", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/RofiThemeSelector.sh"), { desc = "rofi theme selector" })
keybind((vars["mainMod"] or "") .. " CTRL SHIFT + R", hl.dsp.exec_cmd("pkill rofi || true && " .. (vars["scriptsDir"] or "") .. "/RofiThemeSelector-modified.sh"), { desc = "rofi theme selector (modified)" })
keybind((vars["mainMod"] or "") .. " CTRL + K", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/Kitty_themes.sh"), { desc = "Kitty theme selector" })
keybind((vars["mainMod"] or "") .. " SHIFT + B", hl.dsp.exec_cmd((vars["UserScripts"] or "") .. "/RainbowBorders-low-cpu.sh  --run-once"), { desc = "Set static Rainbow Border" })
keybind((vars["mainMod"] or "") .. " SHIFT + H", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/Toggle-Active-Window-Audio.sh"), { desc = "Toggle Mute/Unmute for Active-Window" })
keybind("ALT SHIFT + S", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/hyprshot.sh -m region -o %HOME/Pictures/Screenshots"), { desc = "Hyprshot Screen Capture" })
keybind((vars["mainMod"] or "") .. " SHIFT + F", hl.dsp.window.fullscreen(), { desc = "fullscreen" })
keybind((vars["mainMod"] or "") .. " CTRL + F", hl.dsp.window.fullscreen("1"), { desc = "maximize window" })
keybind((vars["mainMod"] or "") .. " + SPACE", hl.dsp.window.float(), { desc = "Float current window" })
keybind((vars["mainMod"] or "") .. " ALT + SPACE", hl.dsp.exec_cmd("hyprctl dispatch workspaceopt allfloat"), { desc = "Float all windows" })
keybind((vars["mainMod"] or "") .. " SHIFT + Return", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/Dropterminal.sh " .. (vars["term"] or "")), { desc = "DropDown terminal" })
-- Desktop zooming or magnifier
keybind((vars["mainMod"] or "") .. " ALT + mouse_down", hl.dsp.exec_cmd("hyprctl keyword cursor:zoom_factor \"$(hyprctl getoption cursor:zoom_factor | awk 'NR==1 {factor = $2; if (factor < 1) {factor = 1}; print factor * 2.0}')\""), { desc = "zoom in" })
keybind((vars["mainMod"] or "") .. " ALT + mouse_up", hl.dsp.exec_cmd("hyprctl keyword cursor:zoom_factor \"$(hyprctl getoption cursor:zoom_factor | awk 'NR==1 {factor = $2; if (factor < 1) {factor = 1}; print factor / 2.0}')\""), { desc = "zoom out" })
-- Waybar / Bar related
keybind((vars["mainMod"] or "") .. " CTRL ALT + B", hl.dsp.exec_cmd("pkill -SIGUSR1 waybar"), { desc = "toggle waybar on/off" })
keybind((vars["mainMod"] or "") .. " CTRL + B", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/WaybarStyles.sh"), { desc = "waybar styles menu" })
keybind((vars["mainMod"] or "") .. " ALT + B", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/WaybarLayout.sh"), { desc = "waybar layout menu" })
-- Night light toggle (Hyprsunset)
keybind((vars["mainMod"] or "") .. " + N", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/Hyprsunset.sh toggle"), { desc = "toggle night light" })
-- FEATURES / EXTRAS (UserScripts)
keybind((vars["mainMod"] or "") .. " SHIFT + M", hl.dsp.exec_cmd((vars["UserScripts"] or "") .. "/RofiBeats.sh"), { desc = "online music" })
keybind((vars["mainMod"] or "") .. " + W", hl.dsp.exec_cmd((vars["UserScripts"] or "") .. "/WallpaperSelect.sh"), { desc = "select wallpaper" })
keybind((vars["mainMod"] or "") .. " SHIFT + W", hl.dsp.exec_cmd((vars["UserScripts"] or "") .. "/WallpaperEffects.sh"), { desc = "wallpaper effects" })
keybind("CTRL ALT + W", hl.dsp.exec_cmd((vars["UserScripts"] or "") .. "/WallpaperRandom.sh"), { desc = "random wallpaper" })
keybind((vars["mainMod"] or "") .. " CTRL + O", hl.dsp.exec_raw("setprop active opaque toggle"), { desc = "toggle active window opacity" })
keybind((vars["mainMod"] or "") .. " SHIFT + K", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/KeyBinds.sh"), { desc = "search keybinds" })
keybind((vars["mainMod"] or "") .. " SHIFT + A", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/Animations.sh"), { desc = "animations menu" })
keybind((vars["mainMod"] or "") .. " SHIFT + O", hl.dsp.exec_cmd((vars["UserScripts"] or "") .. "/ZshChangeTheme.sh"), { desc = "change oh-my-zsh theme" })
keybind("ALT_L + SHIFT_L", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/KeyboardLayout.sh switch"), { locked = true, desc = "switch keyboard layout globally" })
keybind("SHIFT_L + ALT_L", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/Tak0-Per-Window-Switch.sh"), { locked = true, desc = "switch keyboard layout per-window" })
keybind((vars["mainMod"] or "") .. " ALT + C", hl.dsp.exec_cmd((vars["UserScripts"] or "") .. "/RofiCalc.sh"), { desc = "calculator" })
-- Move current workspaces to monitors (left right up or down)
keybind((vars["mainMod"] or "") .. " CTRL + F9", hl.dsp.exec_raw("movecurrentworkspacetomonitor l"), { desc = "move workspace to left monitor" })
keybind((vars["mainMod"] or "") .. " CTRL + F10", hl.dsp.exec_raw("movecurrentworkspacetomonitor r"), { desc = "move workspace to right monitor" })
keybind((vars["mainMod"] or "") .. " CTRL + F11", hl.dsp.exec_raw("movecurrentworkspacetomonitor u"), { desc = "move workspace to up monitor" })
keybind((vars["mainMod"] or "") .. " CTRL + F12", hl.dsp.exec_raw("movecurrentworkspacetomonitor d"), { desc = "move workspace to down monitor" })
-- ### SYSTEM ####
keybind("CTRL ALT + Delete", hl.dsp.exec_cmd("hyprctl dispatch exit 0"), { desc = "exit Hyprland" })
keybind((vars["mainMod"] or "") .. " + Q", hl.dsp.window.close(), { desc = "close active window" })
keybind((vars["mainMod"] or "") .. " SHIFT + Q", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/KillActiveProcess.sh"), { desc = "Terminate active process" })
keybind((vars["mainMod"] or "") .. " + L", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/LockScreen.sh"), { desc = "lock screen" })
keybind("CTRL ALT + L", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/LockScreen.sh"), { desc = "lock screen" })
keybind("CTRL ALT + P", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/Wlogout.sh"), { desc = "powermenu" })
keybind((vars["mainMod"] or "") .. " SHIFT + N", hl.dsp.exec_cmd("swaync-client -t -sw"), { desc = "notification panel" })
keybind((vars["mainMod"] or "") .. " SHIFT + E", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/Kool_Quick_Settings.sh"), { desc = "Quick settings menu" })
-- Master Layout
keybind((vars["mainMod"] or "") .. " CTRL + D", hl.dsp.exec_raw("layoutmsg removemaster"), { desc = "remove master" })
keybind((vars["mainMod"] or "") .. " + I", hl.dsp.exec_raw("layoutmsg ad1aster"), { desc = "add master" })
-- NOTE: J/K bindings are set dynamically by scripts/KeybindsLayoutInit.sh and scripts/ChangeLayout.sh
-- (we intentionally do not bind them statically here to avoid conflicts across layouts)
-- bindd = $mainMod, J, cycle next, layoutmsg, cyclenext
-- bindd = $mainMod, K, cycle previous, layoutmsg, cycleprev
keybind((vars["mainMod"] or "") .. " CTRL + Return", hl.dsp.exec_raw("layoutmsg swapwithmaster"), { desc = "swap with master" })
-- Dwindle Layout
keybind((vars["mainMod"] or "") .. " SHIFT + I", hl.dsp.exec_raw("togglesplit"), { desc = "toggle split (dwindle)" })
keybind((vars["mainMod"] or "") .. " + P", hl.dsp.window.pseudo(), { desc = "toggle pseudo (dwindle)" })
-- Works on either layout (Master or Dwindle)
keybind((vars["mainMod"] or "") .. " + M", hl.dsp.exec_cmd("hyprctl dispatch splitratio 0.3"), { desc = "set split ratio 0.3" })
-- layout aware keybinds
table.insert(ctx.autostart, { cmd = (vars["scriptsDir"] or "") .. "/ChangeLayout.sh init" })
-- Cycle windows; if floating bring to top
keybind("ALT + tab", hl.dsp.exec_raw("cyclenext"), { desc = "cycle next window" })
keybind("ALT + tab", hl.dsp.window.bring_to_top(), { desc = "bring active to top" })
-- Special Keys / Hot Keys
keybind("XF86AudioRaiseVolume", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/Volume.sh --inc"), { repeating = true, locked = true, desc = "volume up" })
keybind("XF86AudioLowerVolume", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/Volume.sh --dec"), { repeating = true, locked = true, desc = "volume down" })
keybind("ALT + XF86AudioRaiseVolume", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/Volume.sh --inc-precise"), { repeating = true, locked = true, desc = "volume up precise" })
keybind("ALT + XF86AudioLowerVolume", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/Volume.sh --dec-precise"), { repeating = true, locked = true, desc = "volume down precise" })
keybind("XF86AudioMicMute", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/Volume.sh --toggle-mic"), { locked = true, desc = "toggle mic mute" })
keybind("XF86AudioMute", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/Volume.sh --toggle"), { locked = true, desc = "toggle mute" })
keybind("xf86Sleep", hl.dsp.exec_cmd("systemctl suspend"), { locked = true, desc = "sleep" })
keybind("xf86Rfkill", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/AirplaneMode.sh"), { locked = true, desc = "airplane mode" })
-- media controls using keyboards
keybind("XF86AudioPlay", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/MediaCtrl.sh --pause"), { locked = true, desc = "play/pause" })
keybind("XF86AudioPause", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/MediaCtrl.sh --pause"), { locked = true, desc = "pause" })
keybind("XF86AudioNext", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/MediaCtrl.sh --nxt"), { locked = true, desc = "next track" })
keybind("XF86AudioPrev", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/MediaCtrl.sh --prv"), { locked = true, desc = "previous track" })
keybind("XF86AudioStop", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/MediaCtrl.sh --stop"), { locked = true, desc = "stop" })
-- Screenshot keybindings NOTE: You may need to press Fn key as well
keybind((vars["mainMod"] or "") .. " + Print", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/ScreenShot.sh --now"), { desc = "screenshot now" })
keybind((vars["mainMod"] or "") .. " SHIFT + Print", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/ScreenShot.sh --area"), { desc = "screenshot (area)" })
keybind((vars["mainMod"] or "") .. " CTRL + Print", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/ScreenShot.sh --in5"), { desc = "screenshot in 5s" })
keybind((vars["mainMod"] or "") .. " CTRL SHIFT + Print", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/ScreenShot.sh --in10"), { desc = "screenshot in 10s" })
keybind("ALT + Print", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/ScreenShot.sh --active"), { desc = "screenshot active window" })
-- screenshot with swappy (another screenshot tool)
keybind((vars["mainMod"] or "") .. " SHIFT + S", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/ScreenShot.sh --swappy"), { desc = "screenshot (swappy)" })
-- Resize windows
keybind((vars["mainMod"] or "") .. " SHIFT + left", hl.dsp.exec_raw("resizeactive -50 0"), { repeating = true, desc = "resize left (-50)" })
keybind((vars["mainMod"] or "") .. " SHIFT + right", hl.dsp.exec_raw("resizeactive 50 0"), { repeating = true, desc = "resize right (+50)" })
keybind((vars["mainMod"] or "") .. " SHIFT + up", hl.dsp.exec_raw("resizeactive 0 -50"), { repeating = true, desc = "resize up (-50)" })
keybind((vars["mainMod"] or "") .. " SHIFT + down", hl.dsp.exec_raw("resizeactive 0 50"), { repeating = true, desc = "resize down (+50)" })
-- Move windows
keybind((vars["mainMod"] or "") .. " CTRL + left", hl.dsp.exec_raw("movewindow l"), { desc = "move window left" })
keybind((vars["mainMod"] or "") .. " CTRL + right", hl.dsp.exec_raw("movewindow r"), { desc = "move window right" })
keybind((vars["mainMod"] or "") .. " CTRL + up", hl.dsp.exec_raw("movewindow u"), { desc = "move window up" })
keybind((vars["mainMod"] or "") .. " CTRL + down", hl.dsp.exec_raw("movewindow d"), { desc = "move window down" })
-- Swap windows
keybind((vars["mainMod"] or "") .. " ALT + left", hl.dsp.exec_raw("swapwindow l"), { desc = "swap window left" })
keybind((vars["mainMod"] or "") .. " ALT + right", hl.dsp.exec_raw("swapwindow r"), { desc = "swap window right" })
keybind((vars["mainMod"] or "") .. " ALT + up", hl.dsp.exec_raw("swapwindow u"), { desc = "swap window up" })
keybind((vars["mainMod"] or "") .. " ALT + down", hl.dsp.exec_raw("swapwindow d"), { desc = "swap window down" })
-- group
keybind((vars["mainMod"] or "") .. " + G", hl.dsp.group.toggle(), { desc = "toggle group" })
-- Navigate within a group
keybind((vars["mainMod"] or "") .. " + Tab", hl.dsp.exec_raw("changegroupactive f"), { desc = "Change Group Forward" })
keybind((vars["mainMod"] or "") .. " CTRL + tab", hl.dsp.exec_raw("changegroupactive"), { desc = "change active in group" })
keybind((vars["mainMod"] or "") .. " SHIFT + Tab", hl.dsp.exec_raw("changegroupactive b"), { desc = "Change Group Back" })
-- Move window into/out of group
keybind((vars["mainMod"] or "") .. " CTRL + K", hl.dsp.exec_raw("moveintogroup l"), { desc = "Move left into group" })
keybind((vars["mainMod"] or "") .. " CTRL + L", hl.dsp.exec_raw("moveintogroup r"), { desc = "Move Right into group" })
keybind((vars["mainMod"] or "") .. " CTRL + H", hl.dsp.exec_raw("moveoutofgroup"), { desc = "Move active out of group" })
-- Try to dynamically move in grouped window and when ungrouped
-- Not working for me DW 11/26/25  PR: https://github.com/LinuxBeginnings/Hyprland-Dots/pull/872
-- bindd = $mainMod, right, focus right, exec, bash -c 'if hyprctl activewindow -j | jq -e "((.grouped | type) == \"boolean\") or (.address == (.grouped[-1] // empty))" >/dev/null 2>&1; then hyprctl dispatch movefocus r; else hyprctl dispatch changegroupactive f; fi'
-- bindd = $mainMod, left, focus left, exec, bash -c 'if hyprctl activewindow -j | jq -e "((.grouped | type) == \"boolean\") or (.address == (.grouped[0] // empty))" >/dev/null 2>&1; then hyprctl dispatch movefocus l; else hyprctl dispatch changegroupactive b; fi'
-- Move focus with mainMod + arrow keys
keybind((vars["mainMod"] or "") .. " + left", hl.dsp.exec_raw("movefocus l"), { desc = "focus left" })
keybind((vars["mainMod"] or "") .. " + right", hl.dsp.exec_raw("movefocus r"), { desc = "focus right" })
keybind((vars["mainMod"] or "") .. " + up", hl.dsp.exec_raw("movefocus u"), { desc = "focus up" })
keybind((vars["mainMod"] or "") .. " + down", hl.dsp.exec_raw("movefocus d"), { desc = "focus down" })
-- Workspaces related
keybind((vars["mainMod"] or "") .. " + tab", hl.dsp.focus({ workspace = "m+1" }), { desc = "next workspace" })
keybind((vars["mainMod"] or "") .. " SHIFT + tab", hl.dsp.focus({ workspace = "m-1" }), { desc = "previous workspace" })
-- Special workspace
keybind((vars["mainMod"] or "") .. " SHIFT + U", hl.dsp.window.move({ workspace = "special" }), { desc = "move to special workspace" })
keybind((vars["mainMod"] or "") .. " + U", hl.dsp.workspace.toggle_special(), { desc = "toggle special workspace" })
-- Workspace number binds are defined once in hyprland.lua using Hyprland 0.55's documented Lua API.
-- Move active window to a workspace silently mainMod + CTRL [0-9]
keybind((vars["mainMod"] or "") .. " CTRL + code:10", hl.dsp.exec_raw("movetoworkspacesilent 1"), { desc = "move silently to workspace 1" })
keybind((vars["mainMod"] or "") .. " CTRL + code:11", hl.dsp.exec_raw("movetoworkspacesilent 2"), { desc = "move silently to workspace 2" })
keybind((vars["mainMod"] or "") .. " CTRL + code:12", hl.dsp.exec_raw("movetoworkspacesilent 3"), { desc = "move silently to workspace 3" })
keybind((vars["mainMod"] or "") .. " CTRL + code:13", hl.dsp.exec_raw("movetoworkspacesilent 4"), { desc = "move silently to workspace 4" })
keybind((vars["mainMod"] or "") .. " CTRL + code:14", hl.dsp.exec_raw("movetoworkspacesilent 5"), { desc = "move silently to workspace 5" })
keybind((vars["mainMod"] or "") .. " CTRL + code:15", hl.dsp.exec_raw("movetoworkspacesilent 6"), { desc = "move silently to workspace 6" })
keybind((vars["mainMod"] or "") .. " CTRL + code:16", hl.dsp.exec_raw("movetoworkspacesilent 7"), { desc = "move silently to workspace 7" })
keybind((vars["mainMod"] or "") .. " CTRL + code:17", hl.dsp.exec_raw("movetoworkspacesilent 8"), { desc = "move silently to workspace 8" })
keybind((vars["mainMod"] or "") .. " CTRL + code:18", hl.dsp.exec_raw("movetoworkspacesilent 9"), { desc = "move silently to workspace 9" })
keybind((vars["mainMod"] or "") .. " CTRL + code:19", hl.dsp.exec_raw("movetoworkspacesilent 10"), { desc = "move silently to workspace 10" })
keybind((vars["mainMod"] or "") .. " CTRL + bracketleft", hl.dsp.exec_raw("movetoworkspacesilent -1"), { desc = "move silently to previous workspace" })
keybind((vars["mainMod"] or "") .. " CTRL + bracketright", hl.dsp.exec_raw("movetoworkspacesilent +1"), { desc = "move silently to next workspace" })
-- Workspace scroll binds are defined once in hyprland.lua.
-- Move/resize windows with mainMod + LMB/RMB and dragging
keybind((vars["mainMod"] or "") .. " + mouse:272", hl.dsp.exec_raw("movewindow"), { drag = true, desc = "move window" })
keybind((vars["mainMod"] or "") .. " + mouse:273", hl.dsp.exec_raw("resizewindow"), { drag = true, desc = "resize window" })
return true
