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

-- Converted from dms/colors.conf
-- ! Auto-generated file. Do not edit directly.
-- Remove source = ./dms/colors.conf from your config to override.
vars["primary"] = "rgb(89b4fa)"
vars["outline"] = "rgb(6c7086)"
vars["error"] = "rgb(f38ba8)"
hl.config({
  general = {
    col = {
      active_border = (vars["primary"] or ""),
      inactive_border = (vars["outline"] or ""),
    },
}
})
-- Unconverted block line:   groupbar {
hl.config({
  group = {
    col = {
      border_active = (vars["primary"] or ""),
      border_inactive = (vars["outline"] or ""),
      border_locked_active = (vars["error"] or ""),
      border_locked_inactive = (vars["outline"] or ""),
    },
    groupbar = {
      col = {
        active = (vars["primary"] or ""),
        inactive = (vars["outline"] or ""),
        locked_active = (vars["error"] or ""),
        locked_inactive = (vars["outline"] or ""),
      },
    },
}
})
-- Unconverted: }
return true
