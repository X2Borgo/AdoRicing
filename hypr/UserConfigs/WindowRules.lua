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

-- Converted from UserConfigs/WindowRules.conf
-- /* ---- 💫 https://github.com/LinuxBeginnings 💫 ---- */  #
-- For window rules and layerrules
-- See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
-- This file is used to add or overwrite window rules
-- This file will not be modified during dotfiles updates
return true
