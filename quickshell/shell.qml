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
    property var config: ({})

    FileView {
      id: configFile
      path: Qt.resolvedUrl(Quickshell.env("HOME") + "/.config/quickshell/config.json")
      blockLoading: true

      watchChanges: true
      onLoaded: root.loadJson();
      onFileChanged: {
        console.log("reload called");
        Quickshell.reload(false);
        root.loadJson();
      }
      JsonAdapter {
      } 
    }

    function loadJson() {
        try {
            var rawText = typeof configFile.text === "function" ? configFile.text() : configFile.text;
            if (rawText && rawText.length > 0) {
                var parsed = JSON.parse(rawText);
                root.config = parsed;
                Theme.rawConfig = parsed;
            }
        } catch (e) {
            console.log("JSON Parse error: " + e);
        }
    }

    function saveConfig(newConfig){
      root.config = newConfig;
      Theme.rawConfig = newConfig;
      configFile.setText(JSON.stringify(newConfig, null, 2))
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
