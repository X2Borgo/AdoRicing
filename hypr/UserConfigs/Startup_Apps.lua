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

-- Converted from UserConfigs/Startup_Apps.conf
-- /* ---- 💫 https://github.com/LinuxBeginnings 💫 ---- */  #
-- Commands and Apps to be executed at launch
table.insert(ctx.autostart, { cmd = "systemctl --user start kdeconnectd.service" })
-- ydotool daemon: lets the keyboard scroller emit mouse-wheel scroll (see configs/Keybinds.lua)
table.insert(ctx.autostart, { cmd = "bash -lc 'pgrep -x ydotoold >/dev/null || ydotoold'" })
return true
