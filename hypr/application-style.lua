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

-- Converted from application-style.conf
-- /* ---- 💫 https://github.com/LinuxBeginnings 💫 ---- */  #
-- as per Hyprland wiki: hyprland-qt-support provides a QML style for hypr* qt6 apps
vars["roundess"] = "2"
vars["border_width"] = "0"
vars["reduce_motion"] = "false"
return true
