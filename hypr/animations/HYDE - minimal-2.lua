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

-- Converted from animations/HYDE - minimal-2.conf
-- /* ---- 💫 https://github.com/LinuxBeginnings 💫 ---- */  #
-- 
-- # name "Minimal-2"
-- credit https://github.com/prasanthrangan/hyprdots
hl.config({
  animations = {
    enabled = true,
    bezier = "quart, 0.25, 1, 0.5, 1",
    animation = "windows, 1, 6, quart, slide",
    animation = "border, 1, 6, quart",
    animation = "borderangle, 1, 6, quart",
    animation = "fade, 1, 6, quart",
    animation = "workspaces, 1, 6, quart",
}
})
return true
