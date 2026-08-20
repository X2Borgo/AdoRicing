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

-- Converted from wallust/wallust-hyprland.conf
-- Fixed Ado palette (not wallpaper-derived)
vars["background"] = "rgb(0F152E)"
vars["foreground"] = "rgb(E0E0E0)"
vars["color0"] = "rgb(1A2035)"
vars["color1"] = "rgb(232D50)"
vars["color2"] = "rgb(2E3B64)"
vars["color3"] = "rgb(2B65FF)"
vars["color4"] = "rgb(5C8DFF)"
vars["color5"] = "rgb(D000FF)"
vars["color6"] = "rgb(E666FF)"
vars["color7"] = "rgb(C0C0C0)"
vars["color8"] = "rgb(4D556D)"
vars["color9"] = "rgb(00E0B0)"
vars["color10"] = "rgb(4D556D)"
vars["color11"] = "rgb(FFCC00)"
vars["color12"] = "rgb(00F0FF)"
vars["color13"] = "rgb(E0E0E0)"
vars["color14"] = "rgb(80F7FF)"
vars["color15"] = "rgb(FFFFFF)"
return true
