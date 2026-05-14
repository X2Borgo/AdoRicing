---@diagnostic disable: undefined-global
---@type HL.API
local hl = hl
local hypr_dir = (os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config")) .. "/hypr"
package.path = hypr_dir .. "/?.lua;" .. hypr_dir .. "/?/init.lua;" .. package.path
_G.ADO_HYPR = _G.ADO_HYPR or { vars = {}, autostart = {}, loaded = {} }
local ctx = _G.ADO_HYPR
ctx.vars.HOME = os.getenv("HOME") or ""
ctx.vars.configs = hypr_dir .. "/configs"
ctx.vars.UserConfigs = hypr_dir .. "/UserConfigs"
local function require_once(module)
  if not ctx.loaded[module] then
    ctx.loaded[module] = true
    require(module)
  end
end

hl.on("hyprland.start", function()
  for _, item in ipairs(ctx.autostart) do
    hl.exec_cmd(item.cmd, item.rules)
  end
end)

require_once("configs.Keybinds")
require_once("configs.Startup_Apps")
require_once("UserConfigs.Startup_Apps")
require_once("configs.ENVariables")
require_once("UserConfigs.ENVariables")
require_once("configs.Laptops")
require_once("UserConfigs.Laptops")
require_once("UserConfigs.LaptopDisplay")
require_once("configs.WindowRules")
require_once("UserConfigs.WindowRules")
require_once("configs.SystemSettings")
require_once("UserConfigs.UserDecorations")
require_once("UserConfigs.UserAnimations")
require_once("UserConfigs.UserKeybinds")
require_once("UserConfigs.UserSettings")
require_once("UserConfigs.01-UserDefaults")
require_once("monitors")
require_once("workspaces")

-- Workspace binds kept explicit to match Hyprland 0.55's documented Lua form.
-- This avoids legacy dispatcher strings and bypasses generated bind helpers.
local mainMod = "SUPER"

for workspace = 1, 10 do
  local key = workspace % 10
  hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = workspace }), {
    description = "workspace " .. workspace,
  })
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }), {
    description = "move to workspace " .. workspace,
  })
end

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), {
  description = "next existing workspace",
})
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }), {
  description = "previous existing workspace",
})

hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("XDG_SESSION_TYPE", "wayland")
