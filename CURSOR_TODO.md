# Cursor Theme TODO

Current active cursor theme:

`/home/alborghi/.icons/AdoCursorTheme`

## Added As Symlink Aliases

These were added directly under `/home/alborghi/.icons/AdoCursorTheme/cursors/` because they map cleanly to an existing cursor shape:

```text
X_cursor -> cross
all-scroll -> fleur
bottom_left_corner -> ll_angle
bottom_right_corner -> lr_angle
bottom_tee -> bottom_side
cell -> crosshair
context-menu -> pointer
dnd-link -> dnd-copy
dnd-no-drop -> dnd-none
grab -> closedhand
hand -> hand2
hand1 -> hand2
link -> pointer
no-drop -> forbidden
nw-resize -> nw_resize
nwse-resize -> nwse_resize
openhand -> hand2
pointer-move -> pointer_move
right_side -> right_ptr
row-resize -> ns-resize
sb_down_arrow -> s-resize
sb_left_arrow -> w-resize
sb_right_arrow -> e-resize
sb_up_arrow -> n-resize
size-all -> size_all
size-bdiag -> size_bdiag
size-fdiag -> size_fdiag
top_left_arrow -> left_ptr
top_left_corner -> ul_angle
top_right_corner -> ur_angle
top_side -> n-resize
top_tee -> n-resize
vertical-text -> xterm
wayland-cursor -> left_ptr
```

Old Xcursor hash aliases were also added for common legacy client compatibility.

## Remaining Cursors To Design Or Review

These are not present in the current Ado cursor set and should be drawn or intentionally mapped after visual review:

```text
circle
dotbox
draft_large
draft_small
pencil
pirate
plus
right_side
split_h
split_v
zoom-in
zoom-out
```

Notes:

- `right_side` was temporarily mapped to `right_ptr`, but a proper edge-resize cursor may look better.
- `zoom-in` and `zoom-out` need dedicated artwork.
- `pencil`, `plus`, `circle`, `dotbox`, `draft_large`, `draft_small`, and `pirate` are uncommon but may be requested by older X11/XWayland apps.

## SVG Workflow

Raw SVG files cannot be used directly as normal Debian/Hyprland cursor files. The usable output still needs to be compiled Xcursor files:

1. Create or edit SVG source artwork.
2. Render SVG to PNG at one or more target sizes.
3. Compile the PNG frames into Xcursor files with `xcursorgen`.
4. Put the compiled files under `<theme>/cursors/`.

The experimental duplicate theme is:

`/home/alborghi/.icons/AdoCursorTheme-svg-lab`
