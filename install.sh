#!/bin/bash

NAME="ado-theme"
VERSION="1.0.0"
DESCRIPTION="A sleek and modern theme for your application."
echo "Installing $NAME version $VERSION"

# installing sddm theme

SDDM_THEME_DIR="/usr/share/sddm/themes/$NAME"

# if [ ! -d "$SDDM_THEME_DIR" ]; then
#     echo "Creating SDDM theme directory at $SDDM_THEME_DIR"
#     sudo mkdir -p "$SDDM_THEME_DIR"
# fi
# echo "Copying theme files to $SDDM_THEME_DIR"
# sudo cp -r ./ado-sddm/* "$SDDM_THEME_DIR/"

if [ -d "$SDDM_THEME_DIR" ]; then
    sudo rm -rf "$SDDM_THEME_DIR"
    echo "Removed existing SDDM theme directory at $SDDM_THEME_DIR"
fi

echo "Copying theme files to $SDDM_THEME_DIR"
sudo cp -r ./ado-sddm "$SDDM_THEME_DIR"


echo "$NAME theme installation completed."
