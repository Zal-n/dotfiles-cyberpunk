import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "./components"

ShellRoot {
    id: root

    property bool controlCenterOpen: false
    property bool launcherOpen: false
    property bool settingsOpen: false
    property string currentWallpaper: wpFile.text.trim()

    // Háttérkép perszisztencia fájl
    FileView {
        id: wpFile
        path: Quickshell.env("HOME") + "/.config/quickshell/wallpaper.txt"
    }

    IpcHandler {
        target: "shell"

        function toggleControlCenter() { root.controlCenterOpen = !root.controlCenterOpen; }
        function openControlCenter() { root.controlCenterOpen = true; }
        function closeControlCenter() { root.controlCenterOpen = false; }

        function toggleLauncher() { root.launcherOpen = !root.launcherOpen; }
        function openLauncher() { root.launcherOpen = true; }
        function closeLauncher() { root.launcherOpen = false; }

        function toggleSettings() { root.settingsOpen = !root.settingsOpen; }
    }

    IpcHandler {
        target: "wallpaper"

        function set(path: string) {
            root.currentWallpaper = path;
            wpFile.text = path;
        }

        function clear() {
            root.currentWallpaper = "";
            wpFile.text = "";
        }
    }

    BackgroundManager {
        wallpaperPath: root.currentWallpaper
    }

    TopBar {
        onControlCenterToggled: root.controlCenterOpen = !root.controlCenterOpen
        onSettingsToggled: root.settingsOpen = !root.settingsOpen
    }

    ControlCenter {
        visible: root.controlCenterOpen
        onCloseRequested: root.controlCenterOpen = false
    }

    AppLauncher {
        visible: root.launcherOpen
        onCloseRequested: root.launcherOpen = false
    }

    SettingsWindow {
        visible: root.settingsOpen
        onCloseRequested: root.settingsOpen = false
    }
}