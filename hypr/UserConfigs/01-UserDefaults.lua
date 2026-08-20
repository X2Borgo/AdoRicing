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

-- Converted from UserConfigs/01-UserDefaults.conf
-- /* ---- 💫 https://github.com/LinuxBeginnings 💫 ---- */  #
-- This is a file where you put your own default apps, default search Engine etc
-- Set your default editor here uncomment and reboot to take effect.
-- NOTE, this will be automatically uncommented if you select neovim or vim to your default editor
-- env = EDITOR,vim #default editor
-- Define preferred text editor for the KooL Quick Settings Menu (SUPER SHIFT E)
-- script will take the default EDITOR and nano as fallback
vars["edit"] = (vars["EDITOR"] or "nano")
-- These two are for UserKeybinds.conf & Waybar Modules
vars["term"] = "kitty"
vars["files"] = "thunar"
-- Default Search Engine for ROFI Search (SUPER S)
vars["Search_Engine"] = "https://www.google.com/search?q={}"
return true
