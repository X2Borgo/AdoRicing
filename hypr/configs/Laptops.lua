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

-- Converted from configs/Laptops.conf
-- /* ---- 💫 https://github.com/LinuxBeginnings 💫 ---- */  #
-- See https://wiki.hyprland.org/Configuring/Keywords/ for more variable settings
-- These configs are mostly for laptops. This is addemdum to Keybinds.conf
vars["mainMod"] = "SUPER"
vars["scriptsDir"] = home() .. "/.config/hypr/scripts"
vars["UserConfigs"] = home() .. "/.config/hypr/UserConfigs"
-- for disabling Touchpad. hyprctl devices to get device name.
vars["Touchpad_Device"] = "asue1209:00-04f3:319f-touchpad"
keybind("xf86KbdBrightnessDown", hl.dsp.exec_raw((vars["scriptsDir"] or "") .. "/BrightnessKbd.sh --dec"), { repeating = true, desc = "exec" })
keybind("xf86KbdBrightnessUp", hl.dsp.exec_raw((vars["scriptsDir"] or "") .. "/BrightnessKbd.sh --inc"), { repeating = true, desc = "exec" })
keybind("xf86Launch1", hl.dsp.exec_raw("rog-control-center"), { desc = "exec" })
keybind("xf86Launch3", hl.dsp.exec_raw("asusctl led-mode -n"), { desc = "exec" })
keybind("xf86Launch4", hl.dsp.exec_raw("asusctl profile -n"), { desc = "exec" })
keybind("xf86MonBrightnessDown", hl.dsp.exec_raw((vars["scriptsDir"] or "") .. "/Brightness.sh --dec"), { repeating = true, desc = "exec" })
keybind("xf86MonBrightnessUp", hl.dsp.exec_raw((vars["scriptsDir"] or "") .. "/Brightness.sh --inc"), { repeating = true, desc = "exec" })
keybind("xf86TouchpadToggle", hl.dsp.exec_raw((vars["scriptsDir"] or "") .. "/TouchPad.sh"), { desc = "exec" })
-- Screenshot keybindings using F6 (no PrinSrc button)
keybind((vars["mainMod"] or "") .. " + F6", hl.dsp.exec_raw((vars["scriptsDir"] or "") .. "/ScreenShot.sh --now"), { desc = "exec" })
keybind((vars["mainMod"] or "") .. " SHIFT + F6", hl.dsp.exec_raw((vars["scriptsDir"] or "") .. "/ScreenShot.sh --area"), { desc = "exec" })
keybind((vars["mainMod"] or "") .. " CTRL + F6", hl.dsp.exec_raw((vars["scriptsDir"] or "") .. "/ScreenShot.sh --in5"), { desc = "exec" })
keybind((vars["mainMod"] or "") .. " ALT + F6", hl.dsp.exec_raw((vars["scriptsDir"] or "") .. "/ScreenShot.sh --in10"), { desc = "exec" })
keybind("ALT + F6", hl.dsp.exec_raw((vars["scriptsDir"] or "") .. "/ScreenShot.sh --active"), { desc = "exec" })
vars["TOUCHPAD_ENABLED"] = "true"
hl.device({
  name = (vars["Touchpad_Device"] or ""),
  enabled = true,
})
return true
