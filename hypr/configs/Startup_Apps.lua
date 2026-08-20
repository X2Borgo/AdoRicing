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

-- Converted from configs/Startup_Apps.conf
-- /* ---- 💫 https://github.com/LinuxBeginnings 💫 ---- */  #
-- Commands and Apps to be executed at launch (vendor defaults)
vars["scriptsDir"] = home() .. "/.config/hypr/scripts"
vars["UserScripts"] = home() .. "/.config/hypr/UserScripts"
vars["lock"] = (vars["scriptsDir"] or "") .. "/LockScreen.sh"
vars["SwwwRandom"] = (vars["UserScripts"] or "") .. "/WallpaperAutoChange.sh"
vars["livewallpaper"] = ""
vars["wallDIR"] = home() .. "/Pictures/wallpapers"
-- ## wallpaper stuff ###
table.insert(ctx.autostart, { cmd = "swww-daemon --format xrgb" })
-- exec-once = mpvpaper '*' -o "load-scripts=no no-audio --loop" $livewallpaper
-- wallpaper random
-- exec-once = $SwwwRandom $wallDIR # random wallpaper switcher every 30 minutes
-- ## Startup ###
table.insert(ctx.autostart, { cmd = "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP" })
table.insert(ctx.autostart, { cmd = "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP" })
table.insert(ctx.autostart, { cmd = (vars["scriptsDir"] or "") .. "/LaunchKitty.sh", rules = { workspace = "workspace 1 silent" } })
table.insert(ctx.autostart, { cmd = (vars["scriptsDir"] or "") .. "/SaveKittySession.sh --watch" })
table.insert(ctx.autostart, { cmd = (vars["scriptsDir"] or "") .. "/Polkit.sh" })
table.insert(ctx.autostart, { cmd = "nm-applet --indicator" })
table.insert(ctx.autostart, { cmd = "nm-tray" })
-- DMS owns org.freedesktop.Notifications; do not start SwayNC alongside it.
-- exec-once = ags
-- exec-once = blueman-applet
-- exec-once = rog-control-center
table.insert(ctx.autostart, { cmd = (vars["scriptsDir"] or "") .. "/PortalHyprlandUbuntu2604.sh" })
table.insert(ctx.autostart, { cmd = (vars["scriptsDir"] or "") .. "/LaunchShell.sh" })
table.insert(ctx.autostart, { cmd = "hypridle" })
table.insert(ctx.autostart, { cmd = (vars["scriptsDir"] or "") .. "/Hyprsunset.sh init" })
-- Clipboard manager
table.insert(ctx.autostart, { cmd = "wl-paste --type text --watch cliphist store" })
table.insert(ctx.autostart, { cmd = "wl-paste --type image --watch cliphist store" })
-- Rainbow borders (disabled by default; use quick settings menu)
-- exec-once = $UserScripts/RainbowBorders.sh
-- Here are list of features available but disabled by default
-- Persistent wallpaper
-- exec-once = swww-daemon --format xrgb && swww img $wallDIR/mecha-nostalgia.png
-- Gnome polkit for NixOS
-- exec-once = $scriptsDir/Polkit-NixOS.sh
-- xdg-desktop-portal-hyprland (should be auto starting. However, you can force to start)
-- exec-once = $scriptsDir/PortalHyprland.sh
table.insert(ctx.autostart, { cmd = (vars["scriptsDir"] or "") .. "/KeybindsLayoutInit.sh" })
return true
