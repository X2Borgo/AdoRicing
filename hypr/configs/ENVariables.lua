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

-- Converted from configs/ENVariables.conf
-- /* ---- 💫 https://github.com/LinuxBeginnings 💫 ---- */  #
-- Environment variables. See https://wiki.hyprland.org/Configuring/Environment-variables/
-- Set your defaults editor through ENV in ~/.config/hypr/UserConfigs/01-UserDefaults.conf
-- environment-variables
-- Current Version of JakooLit Dotfiles:
hl.env("DOTS_VERSION", "2.3.21")
-- ## Toolkit Backend Variables ###
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("CLUTTER_BACKEND", "wayland")
-- Run SDL2 applications on Wayland.
-- Remove or set to x11 if games that provide older versions of SDL cause compatibility issues
-- env = SDL_VIDEODRIVER,wayland
-- ## XDG Specifications ###
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
-- ## QT Variables ###
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
-- ## hyprland-qt-support ###
hl.env("QT_QUICK_CONTROLS_STYLE", "org.hyprland.style")
-- ## xwayland apps scale fix (useful if you are use monitor scaling) ###
-- Set same value if you use scaling in Monitors.conf
-- 1 is 100% 1.5 is 150%
-- see https://wiki.hyprland.org/Configuring/XWayland/
hl.env("GDK_SCALE", "1")
hl.env("QT_SCALE_FACTOR", "1")
-- Bibata-Modern-Ice-Cursor
-- NOTE! You must have the hyprcursor version to activate this.
-- https://wiki.hyprland.org/Hypr-Ecosystem/hyprcursor/
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_SIZE", "24")
-- ## firefox ###
hl.env("MOZ_ENABLE_WAYLAND", "1")
-- ## electron >28 apps (may help) ###
-- https://www.electronjs.org/docs/latest/api/environment-variables
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
-- ## Hybrid Intel/NVIDIA graphics ###
-- Prefer the Quadro only when its driver has successfully bound the device.
-- AQ_DRM_DEVICES is a COLON-separated list, so /dev/dri/by-path/pci-0000:01:00.0-card
-- cannot be used here: aquamarine splits it on its own colons and finds no GPUs at all,
-- which kills the DRM backend and aborts startup. Resolve the stable PCI address to its
-- colon-free /dev/dri/cardN node instead, so boot-order numbering still doesn't matter.
local nvidia_pci = "0000:01:00.0"
local intel_pci = "0000:00:02.0"

local function readable(path)
  local file = io.open(path, "r")
  if not file then
    return false
  end
  file:close()
  return true
end

-- Returns "/dev/dri/cardN" for a PCI address, or nil if the driver hasn't bound it.
local function card_node_for(pci_address)
  for card = 0, 7 do
    if readable("/sys/bus/pci/devices/" .. pci_address .. "/drm/card" .. card .. "/dev") then
      return "/dev/dri/card" .. card
    end
  end
  return nil
end

local nvidia_card = card_node_for(nvidia_pci)
local intel_card = card_node_for(intel_pci)

local nvidia_ready = readable("/proc/driver/nvidia/gpus/" .. nvidia_pci .. "/information")
  and nvidia_card ~= nil
local nvidia_vaapi_ready = readable("/usr/lib/x86_64-linux-gnu/dri/nvidia_drv_video.so")

-- Leave AQ_DRM_DEVICES unset if neither node resolved: aquamarine's own probing is a far
-- better fallback than an explicit list that names nothing.
if nvidia_ready and intel_card then
  hl.env("AQ_DRM_DEVICES", nvidia_card .. ":" .. intel_card)
  hl.env("GBM_BACKEND", "nvidia-drm")
  hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
elseif nvidia_ready then
  hl.env("AQ_DRM_DEVICES", nvidia_card)
  hl.env("GBM_BACKEND", "nvidia-drm")
  hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
elseif intel_card then
  hl.env("AQ_DRM_DEVICES", intel_card)
end

-- Rendering and video decoding are selected independently. If NVDEC's VA-API
-- bridge is unavailable, keep decoding on Intel instead of falling back to CPU.
if nvidia_ready and nvidia_vaapi_ready then
  hl.env("LIBVA_DRIVER_NAME", "nvidia")
  hl.env("NVD_BACKEND", "direct")
else
  hl.env("LIBVA_DRIVER_NAME", "iHD")
end
hl.env("GSK_RENDERER", "ngl")
-- ## additional ENV's for nvidia. Caution, activate with care ###
-- env = GBM_BACKEND,nvidia-drm
-- env = __GL_GSYNC_ALLOWED,1 #adaptive Vsync
-- env = __NV_PRIME_RENDER_OFFLOAD,1
-- env = __VK_LAYER_NV_optimus,NVIDIA_only
-- env = WLR_DRM_NO_ATOMIC,1
-- ## FOR VM and POSSIBLY NVIDIA ###
-- LIBGL_ALWAYS_SOFTWARE software mesa rendering
-- env = LIBGL_ALWAYS_SOFTWARE,1 # Warning. May cause hyprland to crash
-- env = WLR_RENDERER_ALLOW_SOFTWARE,1
-- ## nvidia firefox ###
-- check this post https://github.com/elFarto/nvidia-vaapi-driver#configuration
-- env = MOZ_DISABLE_RDD_SANDBOX,1
-- env = EGL_PLATFORM,wayland
-- ## Aquamarine Environment Variables (Hyprland > 0.45) ###
-- https://wiki.hyprland.org/Configuring/Environment-variables/#aquamarine-environment-variables----ref-httpsgithubcomhyprwmaquamarineblobmaindocsenvmd---
-- env = AQ_TRACE,1 # Enables more verbose logging.
-- env = AQ_DRM_DEVICES,/dev/dri/card1:/dev/dri/card0 # Set an explicit list of DRM devices (GPUs) to use. It’s a colon-separated list of paths, with the first being the primary. E.g. /dev/dri/card1:/dev/dri/card0
-- env = AQ_MGPU_NO_EXPLICIT,1 # Disables explicit syncing on mgpu buffers
-- env = AQ_NO_MODIFIERS,1 # Disables modifiers for DRM buffers
-- ### Hyprland Environment Variables ####
-- https://wiki.hyprland.org/Configuring/Environment-variables/#hyprland-environment-variables
-- env = HYPRLAND_TRACE,1 # Enables more verbose logging.
-- env = HYPRLAND_NO_RT,1 # Disables realtime priority setting by Hyprland.
-- env = HYPRLAND_NO_SD_NOTIFY,1 # If systemd, disables the 'sd_notify' calls.
-- env = HYPRLAND_NO_SD_VARS,1 # Disables management of variables in systemd and dbus activation environments.
return true
