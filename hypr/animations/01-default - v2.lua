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

-- Converted from animations/01-default - v2.conf
-- /* ---- 💫 https://github.com/LinuxBeginnings 💫 ---- */  #
-- old animations
hl.config({
  animations = {
    enabled = true,
    bezier = "myBezier, 0.05, 0.9, 0.1, 1.05",
    bezier = "linear, 0.0, 0.0, 1.0, 1.0",
    bezier = "wind, 0.05, 0.9, 0.1, 1.05",
    bezier = "winIn, 0.1, 1.1, 0.1, 1.1",
    bezier = "winOut, 0.3, -0.3, 0, 1",
    bezier = "slow, 0, 0.85, 0.3, 1",
    bezier = "overshot, 0.7, 0.6, 0.1, 1.1",
    bezier = "bounce, 1.1, 1.6, 0.1, 0.85",
    bezier = "sligshot, 1, -1, 0.15, 1.25",
    bezier = "nice, 0, 6.9, 0.5, -4.20",
    animation = "windowsIn, 1, 5, slow, popin",
    animation = "windowsOut, 1, 5, winOut, popin",
    animation = "windowsMove, 1, 5, wind, slide",
    animation = "border, 1, 10, linear",
    animation = "borderangle, 1, 180, linear, loop",
    animation = "fade, 1, 5, overshot",
    animation = "workspaces, 1, 5, wind",
    animation = "windows, 1, 5, bounce, popin",
}
})
return true
