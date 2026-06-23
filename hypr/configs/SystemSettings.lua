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

-- Converted from configs/SystemSettings.conf
-- /* ---- 💫 https://github.com/LinuxBeginnings 💫 ---- */  #
-- Default settings
-- This is where you put your own settings as this will not be touched during update
-- if the upgrade.sh is used.
-- refer to Hyprland wiki for more info https://wiki.hyprland.org/Configuring/Variables/
-- NOTE: some settings are in ~/.config/hypr/UserConfigs/UserDecorAnimations.conf
vars["scriptsDir"] = home() .. "/.config/hypr/scripts"
-- smart_split = true
hl.config({
  dwindle = {
    preserve_split = true,
    special_scale_factor = 0.8,
}
})
hl.config({
  master = {
    new_status = "master",
    new_on_top = 1,
    mfact = 0.5,
}
})
hl.config({
  general = {
    resize_on_border = true,
    layout = "dwindle",
}
})
hl.config({
  scrolling = {
    follow_focus = true,
    fullscreen_on_one_column = true,
    wrap_focus = false,
    wrap_swapcol = false,
  },
})
-- accel_profile =     # flat or adaptive or blank or EMPTY means libinput’s default mode
-- Unconverted block line:   touchpad {
hl.config({
  input = {
    kb_layout = "us, it",
    kb_variant = "",
    kb_model = "",
    kb_options = "grp:alt_shift_toggle",
    kb_rules = "",
    repeat_rate = 50,
    repeat_delay = 300,
    sensitivity = 0,
    numlock_by_default = true,
    left_handed = false,
    follow_mouse = 1,
    float_switch_override_focus = false,
    natural_scroll = false,
    touchpad = {
      disable_while_typing = true,
      natural_scroll = true,
      clickfinger_behavior = false,
      middle_button_emulation = false,
      tap_to_click = true,
      drag_lock = false,
    },
    touchdevice = {
      enabled = true,
    },
    tablet = {
      transform = 0,
      left_handed = false,
    },
}
})
-- workspace_swipe_use_r = true #uncomment if wanted a forever create a new workspace with swipe right
hl.config({
  gestures = {
    workspace_swipe_distance = 500,
    workspace_swipe_invert = true,
    workspace_swipe_min_speed_to_force = 30,
    workspace_swipe_cancel_ratio = 0.5,
    workspace_swipe_create_new = true,
    workspace_swipe_forever = true,
}
})
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
-- This only works with HL v0.53+
-- 0 - Default, no change
-- 1 - New focused window takes over fullscreen (Windows-like Alt-Tab)
-- 2 - New focused window stays behind the fullscreen one
hl.config({
  misc = {
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    vrr = 2,
    mouse_move_enables_dpms = true,
    enable_swallow = false,
    swallow_regex = "^(kitty)$",
    focus_on_activate = false,
    initial_workspace_tracking = 0,
    middle_click_paste = false,
    enable_anr_dialog = true,
    anr_missed_pings = 15,
    allow_session_lock_restore = true,
    on_focus_under_fullscreen = 1,
}
})
-- opengl {
-- nvidia_anti_flicker = true
-- }
hl.config({
  binds = {
    workspace_back_and_forth = true,
    allow_workspace_cycles = false,
    window_direction_monitor_fallback = false,
    pass_mouse_when_bound = false,
}
})
-- Could help when scaling and not pixelating
hl.config({
  xwayland = {
    enabled = true,
    force_zero_scaling = true,
}
})
hl.config({
  render = {
    direct_scanout = 0,
}
})
hl.config({
  cursor = {
    sync_gsettings_theme = true,
    no_hardware_cursors = 1,
    enable_hyprcursor = true,
    warp_on_change_workspace = 2,
    no_warps = true,
}
})
return true
