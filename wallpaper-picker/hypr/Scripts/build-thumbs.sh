#!/usr/bin/env bash

set -e

WALL_DIR="$HOME/Images/Wallpapers"
CACHE="$HOME/.cache/wallpaper_picker/thumbs"

mkdir -p "$CACHE"

for img in "$WALL_DIR"/*.{jpg,jpeg,png,webp}; do
    [ -f "$img" ] || continue

    name=$(basename "$img")
    thumb="$CACHE/$name"

    if [ ! -f "$thumb" ]; then
        magick "$img" -resize 320x320^ -gravity center -extent 320x320 "$thumb"
    fi
done
