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

-- Converted from UserConfigs/Laptops.conf
-- /* ---- 💫 https://github.com/LinuxBeginnings 💫 ---- */  #
-- See https://wiki.hyprland.org/Configuring/Keywords/ for more variable settings
-- These configs are mostly for laptops. This is addemdum to Keybinds.conf
vars["mainMod"] = "SUPER"
vars["scriptsDir"] = home() .. "/.config/hypr/scripts"
vars["UserConfigs"] = home() .. "/.config/hypr/UserConfigs"
-- Below are useful when you are connecting your laptop in external display
-- Suggest you edit below for your laptop display
-- From WIKI This is to disable laptop monitor when lid is closed.
-- consult https://wiki.hyprland.org/hyprland-wiki/pages/Configuring/Binds/#switches
-- bindl = , switch:off:Lid Switch,exec,hyprctl keyword monitor "eDP-1, preferred, auto, 1"
-- bindl = , switch:on:Lid Switch,exec,hyprctl keyword monitor "eDP-1, disable"
-- WARNING! Using this method has some caveats!! USE THIS PART WITH SOME CAUTION!
-- CONS of doing this, is that you need to set up your wallpaper (SUPER W) and choose wallpaper.
-- CAVEATS! Sometimes the Main Laptop Monitor DOES NOT have display that it needs to re-connect your external monitor
-- One work around is to ensure that before shutting down laptop, MAKE SURE your laptop lid is OPEN!!
-- Make sure to comment (put # on the both the bindl = , switch ......) above
-- NOTE: Display for laptop are being generated into LaptopDisplay.conf
-- This part is to be use if you do not want your main laptop monitor to wake up during say wallpaper change etc
-- bindl = , switch:off:Lid Switch,exec,echo "monitor = eDP-1, preferred, auto, 1" > $UserConfigs/LaptopDisplay.conf
-- bindl = , switch:on:Lid Switch,exec,echo "monitor = eDP-1, disable" > $UserConfigs/LaptopDisplay.conf
-- for laptop-lid action (to erase the last entry)
-- exec-once = echo "monitor = eDP-1, preferred, auto, 1" > $HOME/.config/hypr/UserConfigs/LaptopDisplay.conf
return true
