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

-- Converted from UserConfigs/LaptopDisplay.conf
-- NOTE, THIS FILE IS BEING USED by disabling Laptop display monitor behaviour when closing lid.
-- See notes on Laptops.conf
-- monitor = eDP-1, preferred, auto, 1
return true
