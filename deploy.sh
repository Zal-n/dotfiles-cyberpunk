#!/usr/bin/env bash
set -e

echo "[+] Installing Quickshell dependencies..."
sudo pacman -S --needed --noconfirm \
    niri \
    qt6-declarative \
    qt6-wayland \
    pipewire \
    wireplumber \
    brightnessctl \
    kitty \
    fish \
    fastfetch \
    btop \
    ttf-jetbrains-mono-nerd

# Check for Quickshell package (from AUR or official repositories)
if ! command -v quickshell &> /dev/null; then
    echo "[+] Building quickshell..."
    yay -S --noconfirm quickshell-git || echo "Install quickshell manually from AUR"
fi

mkdir -p ~/.config/{theme,quickshell/components,niri,kitty,fish}

echo "[+] Quickshell Cyberpunk DE ready!"