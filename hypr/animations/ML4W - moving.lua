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

-- Converted from animations/ML4W - moving.conf
-- /* ---- 💫 https://github.com/LinuxBeginnings 💫 ---- */  #
-- 
-- name "Moving"
-- credit https://github.com/mylinuxforwork/dotfiles
hl.config({
  animations = {
    enabled = true,
    bezier = "overshot, 0.05, 0.9, 0.1, 1.05",
    bezier = "smoothOut, 0.5, 0, 0.99, 0.99",
    bezier = "smoothIn, 0.5, -0.5, 0.68, 1.5",
    animation = "windows, 1, 5, overshot, slide",
    animation = "windowsOut, 1, 3, smoothOut",
    animation = "windowsIn, 1, 3, smoothOut",
    animation = "windowsMove, 1, 4, smoothIn, slide",
    animation = "border, 1, 5, default",
    animation = "fade, 1, 5, smoothIn",
    animation = "fadeDim, 1, 5, smoothIn",
    animation = "workspaces, 1, 6, default",
}
})
return true
