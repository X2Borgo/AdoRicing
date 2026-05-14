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

-- Converted from animations/03- Disable Animation.conf
-- /* ---- 💫 https://github.com/LinuxBeginnings 💫 ---- */  #
hl.config({
  animations = {
    enabled = false,
}
})
return true
