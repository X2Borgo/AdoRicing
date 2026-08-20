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

-- Converted from animations/Mahaveer - me-2.conf
-- /* ---- 💫 https://github.com/LinuxBeginnings 💫 ---- */  #
-- 
-- name "Me-2"
-- credit https://github.com/mahaveergurjar
-- animations for -git or version >0.42.0
hl.config({
  animations = {
    enabled = true,
    bezier = "wind, 0.05, 0.9, 0.1, 1.05",
    bezier = "winIn, 0.1, 1.1, 0.1, 1.1",
    bezier = "winOut, 0.3, -0.3, 0, 1",
    bezier = "liner, 1, 1, 1, 1",
    bezier = "overshot, 0.05, 0.9, 0.1, 1.05",
    bezier = "smoothOut, 0.5, 0, 0.99, 0.99",
    bezier = "smoothIn, 0.5, -0.5, 0.68, 1.5",
    animation = "windows, 1, 6, wind, slide",
    animation = "windowsIn, 1, 5, winIn, slide",
    animation = "windowsOut, 1, 3, smoothOut, slide",
    animation = "windowsMove, 1, 5, wind, slide",
    animation = "border, 1, 1, liner",
    animation = "borderangle, 1, 180, liner, loop",
    animation = "fade, 1, 3, smoothOut",
    animation = "workspaces, 1, 5, overshot",
    animation = "workspacesIn, 1, 5, winIn, slide",
    animation = "workspacesOut, 1, 5, winOut, slide",
}
})
return true
