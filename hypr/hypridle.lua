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

-- Converted from hypridle.conf
-- /* ---- 💫 https://github.com/LinuxBeginnings 💫 ---- */  #
-- Hypridle
-- Original config submitted by https://github.com/SherLock707
vars["iDIR"] = home() .. "/.config/swaync/images/ja.png"
vars["scriptsDir"] = home() .. "/.config/hypr/scripts"
-- unlock_cmd = killall hyprlock # kills hyprlock when unlocking (this is always run when "loginctl unlock-session" is called)
hl.config({
  general = {
    lock_cmd = (vars["scriptsDir"] or "") .. "/LockScreen.sh --logind-hook",
    before_sleep_cmd = "loginctl lock-session",
    after_sleep_cmd = "hyprctl dispatch dpms on",
    ignore_dbus_inhibit = false,
}
})
-- turn off screen faster if session is already locked
-- (disabled by default)
-- listener {
-- timeout = 30                            # 30 seconds
-- on-timeout = pidof hyprlock && hyprctl dispatch dpms off # turns off the screen if hyprlock is active
-- on-resume = pidof hyprlock && hyprctl dispatch dpms on    # command to run when activity is detected after timeout has fired.
-- }
-- Warn
hl.config({
  listener = {
    timeout = 540,
    on_timeout = "notify-send -i " .. (vars["iDIR"] or "") .. " \" You are idle!\"",
    on_resume = "notify-send -i " .. (vars["iDIR"] or "") .. " \" Oh! you're Back\" \" Hello !!!\"",
}
})
-- Screenlock
-- on-resume = notify-send -i $iDIR " System Unlocked!"  # command to run when activity is detected after timeout has fired.
hl.config({
  listener = {
    timeout = 600,
    on_timeout = "loginctl lock-session",
}
})
-- Turn off screen
-- (disabled by default)
-- listener {
-- timeout = 630                            # 10.5 min
-- on-timeout = hyprctl dispatch dpms off  # command to run when timeout has passed
-- on-resume = hyprctl dispatch dpms on    # command to run when activity is detected after timeout has fired.
-- }
-- Suspend # disabled by default
-- listener {
-- timeout = 1200                            # 20 min
-- on-timeout = systemctl suspend # command to run when timeout has passed
-- on-resume = notify-send -i $iDIR " Oh! you're back" "Hello !!!"  # command to run when activity is detected after timeout has fired.
-- }
return true
