# Cyberpunk Dotfiles

A neon cyberpunk desktop environment for **Arch Linux**, built around the [Niri](https://github.com/YaLTeR/niri) scrollable-tiling Wayland compositor and [Quickshell](https://quickshell.org/).

The configuration combines a shared cyan, magenta, and yellow palette across the compositor, shell, terminal, launcher, status bar, and Fish prompt.

## Included

- **Niri**: scrollable tiling layout, workspace navigation, borders, and startup configuration
- **Quickshell**: top bar, application launcher, control center, settings window, and wallpaper handling
- **Waybar**: workspaces, focused window, clock, CPU, memory, battery, network, and tray modules
- **Kitty**: JetBrains Mono Nerd Font and synchronized terminal colors
- **Fish**: themed command-line colors plus `fetch` and `top` aliases
- **Rofi**: cyberpunk launcher theme
- **Theme**: shared colors in `theme/palette.json`
- **Wallpaper**: included `wallpaper.png`

## Requirements

- Arch Linux with `pacman`
- A running Wayland session
- `sudo` access
- `yay` or another AUR helper for `quickshell-git`

The deployment script installs these packages:

- `niri`
- `quickshell-git`
- `qt6-declarative`
- `qt6-wayland`
- `pipewire` and `wireplumber`
- `brightnessctl`
- `kitty`
- `fish`
- `fastfetch`
- `btop`
- `ttf-jetbrains-mono-nerd`

## Installation

Clone the repository and run the deployment script:

```bash
git clone https://github.com/sbalazs222/dotfiles-cyberpunk.git
cd dotfiles-cyberpunk
chmod +x deploy.sh
./deploy.sh
```

The script installs dependencies and creates the main configuration directories under `~/.config`. Copy or symlink the repository's configuration files into those directories as needed for your setup:

```bash
mkdir -p ~/.config/{theme,quickshell,niri,kitty,fish,waybar,rofi}
cp -r theme/* ~/.config/theme/
cp -r quickshell/* ~/.config/quickshell/
cp niri/config.kdl ~/.config/niri/config.kdl
cp kitty/kitty.conf ~/.config/kitty/kitty.conf
cp fish/config.fish ~/.config/fish/config.fish
cp waybar/* ~/.config/waybar/
cp rofi/* ~/.config/rofi/
cp wallpaper.png ~/.config/quickshell/wallpaper.png
```

Start Niri from your display manager or TTY. Quickshell is started automatically by `niri/config.kdl`.

## Keybindings

The default Niri modifier is `Mod` (typically the Super/Windows key).

| Binding | Action |
| --- | --- |
| `Mod + T` | Open Kitty |
| `Mod + A` | Toggle Quickshell application launcher |
| `Mod + C` | Toggle Quickshell control center |
| `Mod + F` | Maximize the focused column |
| `Mod + Shift + F` | Toggle fullscreen |
| `Mod + Q` | Close the focused window |
| `Mod + H` / `Mod + Left` | Focus the column to the left |
| `Mod + L` / `Mod + Right` | Focus the column to the right |
| `Mod + J` / `Mod + Down` | Focus the window or workspace below |
| `Mod + K` / `Mod + Up` | Focus the window or workspace above |
| `Mod + 1` ... `Mod + 4` | Focus workspace 1 through 4 |
| `Mod + Shift + 1` ... `Mod + Shift + 4` | Move the column to workspace 1 through 4 |
| `Mod + Shift + E` | Quit Niri |

## Customization

- Change shared colors and font settings in `theme/palette.json`.
- Adjust monitor resolution and scale in `niri/config.kdl`.
- Edit Quickshell components under `quickshell/components/`.
- Set a wallpaper through the Quickshell settings UI or IPC:

```bash
quickshell ipc call wallpaper set "$HOME/.config/quickshell/wallpaper.png"
```

- Update status bar modules in `waybar/config.jsonc` and their appearance in `waybar/style.css`.

## Notes

The supplied Niri output is configured for an `eDP-1` display at `1920x1080@165Hz`. Adjust or remove that output block if your monitor differs. The deployment script prepares dependencies and directories; it does not replace existing files automatically.

## License

No license has been specified yet.