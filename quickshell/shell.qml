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
    readonly property var defaultConfig: ({
        "theme": {
            "bg": "#0a0b10",
            "surface": "#121520",
            "surfaceAccent": "#1a1e2d",
            "cyan": "#00f0ff",
            "magenta": "#ff0055",
            "yellow": "#ffe600",
            "fg": "#e0e6ed",
            "fgDim": "#565f89",
            "fontFamily": "JetBrainsMono Nerd Font"
        },
        "desktop": {
            "wallpaper": "",
            "barHeight": 38,
            "cornerCutSize": 25,
            "cornerCutSizeSmall": 15
        },
        "topbar": {
            "left": [
                { "id": "logo", "preset": "sys-niri" }
            ],
            "center": [
                { "id": "clock", "preset": "time-date" }
            ],
            "right": [
                { "id": "settings", "preset": "default" },
                { "id": "controlCenter", "preset": "default" }
            ]
        },
        "hardware": {
            "brightnessDevice": "intel_backlight",
            "audioSink": "@DEFAULT_AUDIO_SINK@"
        }
    })
    property var config: ({})
    property var topbarPresets: ({})

    FileView {
      id: configFile
      path: Qt.resolvedUrl(Quickshell.env("HOME") + "/.config/quickshell/config.json")
      blockLoading: true

      watchChanges: true
      onLoaded: root.loadJson()
      onFileChanged: configFile.reload()
      onLoadFailed: root.createDefaultConfig(error)
      JsonAdapter {
      } 
    }

    FileView {
      id: topbarPresetsFile
      path: Qt.resolvedUrl(Quickshell.env("HOME") + "/.config/quickshell/presets/topbar.json")
      blockLoading: true
      watchChanges: true

      onLoaded: root.loadTopbarPresets()
      onFileChanged: topbarPresetsFile.reload()
      onLoadFailed: console.log("TopBar presets load error: " + FileViewError.toString(error))
    }

    function loadJson() {
        try {
            var rawText = typeof configFile.text === "function" ? configFile.text() : configFile.text;
            if (!rawText || rawText.trim().length === 0) {
                throw new Error("configuration file is empty");
            }

            var parsed = JSON.parse(rawText);
            if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
                throw new Error("configuration root must be an object");
            }
            root.applyConfig(parsed);
        } catch (e) {
            console.log("JSON config parse error: " + e);
        }
    }

    function applyConfig(newConfig) {
      root.config = newConfig;
      Theme.rawConfig = newConfig;
    }

    function loadTopbarPresets() {
      try {
        var rawText = typeof topbarPresetsFile.text === "function" ? topbarPresetsFile.text() : topbarPresetsFile.text;
        var parsed = JSON.parse(rawText);
        if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
          throw new Error("TopBar presets root must be an object");
        }
        root.topbarPresets = parsed;
      } catch (e) {
        console.log("TopBar presets parse error: " + e);
      }
    }

    function saveConfig(newConfig) {
      root.applyConfig(newConfig);
      configFile.setText(JSON.stringify(newConfig, null, 2));
    }

    function createDefaultConfig(error) {
      if (error !== FileViewError.FileNotFound) {
        console.log("JSON config load error: " + FileViewError.toString(error));
        return;
      }

      var defaults = JSON.parse(JSON.stringify(root.defaultConfig));
      root.applyConfig(defaults);
      configFile.setText(JSON.stringify(defaults, null, 2));
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

      function getConfig() { return root.config; }
    }

    IpcHandler {
      target: "wallpaper"

      function set(path: string) {
        var cfg = root.config;
        if(!cfg.desktop) cfg.desktop = {};
        cfg.desktop.wallpaper = path;
        root.saveConfig(cfg);
      }

      function clear() {
        var cfg = root.config;
        if (!cfg.desktop) cfg.desktop = {};
        cfg.desktop.wallpaper = "";
        root.saveConfig(cfg);
      }
    }

    BackgroundManager {
      wallpaperPath: root.config.desktop?.wallpaper ?? ""
    }

    TopBar {
      onControlCenterToggled: root.controlCenterOpen = !root.controlCenterOpen
      onSettingsToggled: root.settingsOpen = !root.settingsOpen
    }

    ControlCenter {
      visible: root.controlCenterOpen
      onCloseRequested: root.controlCenterOpen = false
      onOpenSettingsRequested: {
        root.controlCenterOpen = false;
        root.settingsOpen = true;
      }
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
