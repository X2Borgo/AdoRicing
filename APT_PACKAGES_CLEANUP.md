# APT Package Cleanup Notes

Generated from the local Debian 13 `trixie` APT state.

Current system:

```text
Debian GNU/Linux 13 (trixie)
Running kernel: 6.12.90+deb13.1-amd64
```

`apt-get -s autoremove` reported:

```text
0 upgraded, 0 newly installed, 0 to remove
```

That means APT does not currently see any orphaned dependency packages. Cleanup should be based on packages you personally no longer use.

Last verified status: the following cleanup candidates are still installed:

```text
epiphany-browser
firefox-esr
luakit
opera-stable
snapd
steam-launcher
wine
```

## Browser Decision

Current browser choice:

```text
Primary browser: Zen
Alternative browser to keep: google-chrome-stable
```

Unused browser packages that can be removed:

```text
epiphany-browser
firefox-esr
luakit
opera-stable
```

Verified installed browser packages:

```text
epiphany-browser
firefox-esr
google-chrome-stable
luakit
opera-stable
```

## Can Be Removed If Unused

These are optional or user-facing packages. Remove only the ones you know you do not use.

```text
analog
apache2-doc
apt-file
apt-listchanges
apt-transport-https
aptakube
black
blueman
bruno
btop
cava
claude-desktop
code
discord
flatpak
freelens
gh
htop
inkscape
kamoso
kitty
mpv
nano
ncdu
obs-studio
qalculate-gtk
reportbug
snapd
spotify-client
steam-launcher
tree
vim-tiny
w3m
wine
yt-dlp
```

## Large Optional Stacks

### CUDA Development

```text
nvidia-cuda-toolkit
```

Remove this only if you do not compile or run CUDA development workloads. A simulated removal showed many CUDA libraries and tools would become autoremovable afterward.

### Extra KDE Bundles

```text
kde-full
kdeedu
kdegames
kdepim
kdesdk
kdetoys
kdewebdev
```

These are KDE bundle/metapackages. Removing them does not immediately remove the core Plasma desktop, but it makes many KDE apps, games, education tools, PIM tools, and SDK tools autoremovable afterward.

## Conditional Packages

Keep these if you use gaming, Proton, Steam libraries, Windows compatibility, Bottles, Lutris, or manually run Windows applications.

```text
steam-launcher
steam-libs-amd64
steam-libs-i386:i386
wine
wine32:i386
wine64
```

Remove them only if you do not use Steam, Proton, Wine, Bottles, Lutris, or Windows apps.

## Next Removal Candidates

Conservative next candidates, if unused:

```text
epiphany-browser
firefox-esr
luakit
opera-stable
snapd
apache2-doc
analog
reportbug
w3m
vim-tiny
nano
sl
```

Larger optional apps, if unused:

```text
bruno
claude-desktop
code
discord
freelens
inkscape
kamoso
mpv
obs-studio
spotify-client
```

Development stacks, if unused:

```text
nvidia-cuda-toolkit
clang-21
clang-tools-21
llvm-21
lld-21
qt5ct
qt6ct
qtbase5-dev
qtdeclarative5-dev
qt6-3d-dev
qt6-5compat-dev
qt6-base-dev
qt6-base-private-dev
qt6-charts-dev
qt6-declarative-dev
qt6-shadertools-dev
qt6-svg-dev
qt6-tools-dev
qt6-wayland-dev
qt6-wayland-private-dev
```

## Old Kernel Candidate

The currently running kernel is:

```text
6.12.90+deb13.1-amd64
```

These older `6.12.73` packages are likely removable:

```text
linux-image-6.12.73+deb13-amd64-unsigned
linux-headers-6.12.73+deb13-amd64
linux-headers-6.12.73+deb13-common
linux-kbuild-6.12.73+deb13
```

Keep at least one known-good fallback kernel installed.

## Do Not Remove

These are base system, boot, package manager, core runtime, firmware, or essential utility packages.

```text
adduser
apt
base-files
base-passwd
bash
bsdutils
ca-certificates
coreutils
dash
dbus
debconf
debian-archive-keyring
debianutils
diffutils
dpkg
e2fsprogs
findutils
firmware-intel-graphics
firmware-intel-misc
firmware-iwlwifi
firmware-misc-nonfree
firmware-nvidia-graphics
firmware-sof-signed
grub-common
grub-efi-amd64
gzip
hostname
init
init-system-helpers
initramfs-tools
intel-microcode
iproute2
iputils-ping
kmod
less
libc6
linux-image-amd64
login
mount
nftables
openssh-client
passwd
perl-base
procps
sed
shim-signed
systemd
systemd-sysv
tar
tzdata
udev
util-linux
wpasupplicant
xz-utils
zlib1g
```

## Do Not Remove Unless Replacing

These are important for your current desktop, networking, drivers, containers, VPN, input method, or Wayland session. Remove only if you know the replacement path.

```text
kde-full
task-kde-desktop
sddm
network-manager-gnome
pipewire
wireplumber
nvidia-driver
docker-ce
tailscale
fcitx5
niri
waybar
xdg-desktop-portal
xdg-desktop-portal-kde
xwayland
```

## Safe Workflow

Always simulate removals first:

```bash
sudo apt-get -s remove PACKAGE_NAMES
```

If the simulated removal looks correct, run the real removal:

```bash
sudo apt remove PACKAGE_NAMES
sudo apt autoremove
```

Example first cleanup, only if these are unused:

```bash
sudo apt-get -s remove epiphany-browser firefox-esr luakit opera-stable snapd wine steam-launcher
```
