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

-- Converted from UserConfigs/UserKeybinds.conf
-- /* ---- 💫 https://github.com/LinuxBeginnings 💫 ---- */  #
-- This is where you put your own keybinds. Be Mindful to check as well ~/.config/hypr/configs/Keybinds.conf to avoid conflict
-- if you think I should replace the Pre-defined Keybinds in ~/.config/hypr/configs/Keybinds.conf , submit an issue or let me know in DC and present me a valid reason as to why, such as conflicting with global shortcuts, etc etc
-- See https://wiki.hyprland.org/Configuring/Keywords/ for more settings and variables
-- See also Laptops.conf for laptops keybinds
-- /* ---- ✴️ Variables ✴️ ---- */  #
vars["mainMod"] = "SUPER"
vars["scriptsDir"] = home() .. "/.config/hypr/scripts"
vars["UserScripts"] = home() .. "/.config/hypr/UserScripts"
vars["UserConfigs"] = home() .. "/.config/hypr/UserConfigs"
-- IMPORTANT: If you want to remap and existing keybind you MUST unbindd it first
-- The bindings are CASE SENSITIVE. We suggest you copy the exisitng binding here
-- Then change `bindd` to `unbind`
-- E.g.
-- unbind = $mainMod, Return, Open terminal, exec, $term
-- bindd = $mainMod, Return, Open terminal, exec, ghostty
-- 
-- unbind = $mainMod, E, file manager, exec, $files
-- bindd = $mainMod, T, file manager, exec, $files
-- If you are ADDING a bindd, make sure you include the description
-- Other the keybind search menu might not show it properly
-- E.g.
-- bindd = $mainMod, Z, My z app, exec APPNAME
-- Numpad shortcuts with NumLock off
keybind((vars["mainMod"] or "") .. " + KP_End", hl.dsp.exec_cmd("kitty"), { desc = "open kitty from numpad 1" })
keybind((vars["mainMod"] or "") .. " + KP_Down", hl.dsp.exec_cmd("zed"), { desc = "open zed from numpad 2" })
keybind((vars["mainMod"] or "") .. " + KP_Next", hl.dsp.exec_cmd("/home/alborghi/.local/share/applications/downloaded/zen/zen"), { desc = "open zen from numpad 3" })
keybind((vars["mainMod"] or "") .. " + KP_Left", hl.dsp.exec_cmd("dolphin"), { desc = "open thunar from numpad 4" })
-- For passthrough keyboard into a VM
-- bind = $mainMod ALT, P, submap, passthru
-- submap = passthru
-- to unbind
-- bind = $mainMod ALT, P, submap, reset
-- submap = reset
-- Named workspace presets
keybind((vars["mainMod"] or "") .. " + F1", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/WorkspacePreset.sh work"), { desc = "open work workspace preset" })
keybind((vars["mainMod"] or "") .. " + F2", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/WorkspacePreset.sh drevia"), { desc = "open drevia workspace preset" })
keybind((vars["mainMod"] or "") .. " SHIFT + F1", hl.dsp.exec_raw("movetoworkspace name:work"), { desc = "move window to work workspace" })
keybind((vars["mainMod"] or "") .. " SHIFT + F2", hl.dsp.exec_raw("movetoworkspace name:drevia"), { desc = "move window to drevia workspace" })
-- Clipboard-only area screenshot
keybind((vars["mainMod"] or "") .. " + X", hl.dsp.exec_cmd((vars["scriptsDir"] or "") .. "/ScreenShot.sh --clip-area"), { desc = "screenshot area to clipboard" })
return true
