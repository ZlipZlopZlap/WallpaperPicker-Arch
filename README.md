# WallpaperPicker-Arch
An Arch config for the wallpaper picker designed by [ilyamiro](https://github.com/ilyamiro)

### Contributors
- [ilyamiro](https://github.com/ilyamiro)
- [ZlipZlopZlap](https://github.com/ZlipZlopZlap)
- [vladimir2090](https://github.com/vladimir2090)

## Requirements
- quickshell
- swww
- hyprland
- imagemagick

## Notes
- Thumbnails are cached in `~/.cache/wallpaper_picker/`
- Save wallpapers to `~/Images/Wallpapers`
- Put `build-thumbs.sh` in `~/wallpaper-pick/hypr/Scripts/`
- If you use matugen, configure its `config.toml` accordingly (see Matugen Support below)

## Extras
- Added keyboard navigation to move left **A** & right **D**
- **Enter** selects and closes the switcher
- Designed on a 1440p monitor – another man tested on my 1080p monitor and it worked fine
- Thumbnail picker loads images faster in the selector

## Structure
Exactly like ilyamiro's – follow his layout.

## Generate thumbnails
Run `~/wallpaper-pick/hypr/Scripts/build-thumbs.sh`  
Or refer to `keybind.conf`.

## Matugen Support (Optional)
Dynamic color generation via [matugen](https://github.com/InioX/matugen) is now supported.

- **Disabled by default** (just picks wallpaper, colors won't change)
- **Enable with environment variable**:
  ```bash
  env WALLPICKER_MATUGEN=1 quickshell -c ~/.config/quickshell
  ```
- Example Hyprland keybinds:
  ```ini
  # Normal picker (no matugen)
  bind = SUPER, W, exec, quickshell -c ~/.config/quickshell

  # With matugen
  bind = SUPER SHIFT, W, exec, env WALLPICKER_MATUGEN=1 quickshell -c ~/.config/quickshell
  ```
- Requires matugen installed. If it's not found, a notification is shown and the picker continues without color generation.

## Auto-start (Restore last wallpaper)
Add these lines to your `~/.config/hypr/hyprland.conf` to restore the last selected wallpaper on login:
```ini
# Start swww daemon
exec-once = swww-daemon --format argb

# Restore last selected wallpaper (reads from cache file)
exec-once = bash -c 'sleep 1; f=~/.config/hypr/extra/current-wallpaper; [[ -f "$f" && -f "$(cat "$f")" ]] && swww img "$(cat "$f")" --transition-type none'
```

## Monitor Configuration (Important!)
The picker needs to know your monitor output name (e.g., `DP-1`, `eDP-1`, `HDMI-A-1`).  
Check the following line in `wallpaper-picker/Shell/wallpaper/WallpaperPicker.qml`:

```qml
// Line 14
readonly property string targetOutput: Quickshell.env("QS_TARGET_OUTPUT") || "DP-1"
```

- **Default fallback**: `DP-1` (common for desktops)
- **For laptops**: likely `eDP-1`
- **Check your output**: run `hyprctl monitors | grep Monitor`

---

If I've missed anything, let me know!
