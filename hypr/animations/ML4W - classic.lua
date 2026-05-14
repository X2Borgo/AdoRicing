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

-- Converted from animations/ML4W - classic.conf
-- /* ---- 💫 https://github.com/LinuxBeginnings 💫 ---- */  #
-- 
-- name "Classic"
-- credit https://github.com/mylinuxforwork/dotfiles
hl.config({
  animations = {
    enabled = true,
    bezier = "myBezier, 0.05, 0.9, 0.1, 1.05",
    animation = "windows, 1, 7, myBezier",
    animation = "windowsOut, 1, 7, default, popin 80%",
    animation = "border, 1, 10, default",
    animation = "borderangle, 1, 8, default",
    animation = "fade, 1, 7, default",
    animation = "workspaces, 1, 6, default",
}
})
return true
