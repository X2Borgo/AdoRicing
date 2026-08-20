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

-- Converted from animations/HYDE - default.conf
-- /* ---- 💫 https://github.com/LinuxBeginnings 💫 ---- */  #
-- 
-- name "Default"
-- credit https://github.com/prasanthrangan/hyprdots
hl.config({
  animations = {
    enabled = true,
    bezier = "wind, 0.05, 0.9, 0.1, 1.05",
    bezier = "winIn, 0.1, 1.1, 0.1, 1.1",
    bezier = "winOut, 0.3, -0.3, 0, 1",
    bezier = "liner, 1, 1, 1, 1",
    animation = "windows, 1, 6, wind, slide",
    animation = "windowsIn, 1, 6, winIn, slide",
    animation = "windowsOut, 1, 5, winOut, slide",
    animation = "windowsMove, 1, 5, wind, slide",
    animation = "border, 1, 1, liner",
    animation = "borderangle, 1, 30, liner, once",
    animation = "fade, 1, 10, default",
    animation = "workspaces, 1, 5, wind",
    animation = "specialWorkspace, 1, 5, wind, slidevert",
}
})
return true
