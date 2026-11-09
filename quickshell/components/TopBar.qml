import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "topbar"

PanelWindow {
    id: bar
    signal controlCenterToggled()
    signal settingsToggled()

    readonly property var cfg: root.config.topbar ?? ({})
    readonly property var presets: root.topbarPresets
    property var popupModules: ({})

    WlrLayershell.layer: WlrLayer.Top

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight
    color: Theme.bg

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        implicitHeight: 2
        color: Theme.cyan
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16

        RowLayout {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12
            Repeater {
                model: bar.cfg.left ?? []
                delegate: Loader {
                    property var moduleConfig: modelData
                    Layout.preferredWidth: item ? bar.moduleWidth(item) : 0
                    Layout.preferredHeight: item ? bar.moduleHeight(item) : 0
                    sourceComponent: bar.moduleComponent(modelData.id)
                    onLoaded: {
                        item.topbar = bar;
                        item.moduleConfig = moduleConfig;
                        bar.registerPopupModule(item);
                    }
                }
            }
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: 12
            Repeater {
                model: bar.cfg.center ?? []
                delegate: Loader {
                    property var moduleConfig: modelData
                    Layout.preferredWidth: item ? bar.moduleWidth(item) : 0
                    Layout.preferredHeight: item ? bar.moduleHeight(item) : 0
                    sourceComponent: bar.moduleComponent(modelData.id)
                    onLoaded: {
                        item.topbar = bar;
                        item.moduleConfig = moduleConfig;
                        bar.registerPopupModule(item);
                    }
                }
            }
        }

        RowLayout {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Repeater {
                model: bar.cfg.right ?? []
                delegate: Loader {
                    property var moduleConfig: modelData
                    Layout.preferredWidth: item ? bar.moduleWidth(item) : 0
                    Layout.preferredHeight: item ? bar.moduleHeight(item) : 0
                    sourceComponent: bar.moduleComponent(modelData.id)
                    onLoaded: {
                        item.topbar = bar;
                        item.moduleConfig = moduleConfig;
                        bar.registerPopupModule(item);
                    }
                }
            }
        }
    }

    function modulePreset(module) {
        return bar.presets[module.id]?.[module.preset ?? "default"] ?? ({});
    }

    function registerPopupModule(module) {
        if (module.popupKey !== undefined) {
            bar.popupModules[module.popupKey] = module;
        }
    }

    function togglePopup(module) {
        var shouldOpen = !module.popupOpen;
        Object.keys(bar.popupModules).forEach(function(key) {
            bar.popupModules[key].popupOpen = false;
        });
        module.popupOpen = shouldOpen;
    }

    function closePopups() {
        Object.keys(bar.popupModules).forEach(function(key) {
            bar.popupModules[key].popupOpen = false;
        });
    }

    function moduleWidth(module) {
        return module.width > 0 ? module.width : module.implicitWidth;
    }

    function moduleHeight(module) {
        return module.height > 0 ? module.height : module.implicitHeight;
    }

    function moduleComponent(moduleId) {
        switch (moduleId) {
        case "logo":
            return logoModule;
        case "clock":
            return clockModule;
        case "settings":
            return settingsModule;
        case "controlCenter":
            return controlCenterModule;
        case "separator":
            return separatorModule;
        case "workspaceDisplay":
            return workspaceDisplayModule;
        case "battery":
            return batteryModule;
        case "wifi":
            return wifiModule;
        default:
            return null;
        }
    }

    function presetColor(name) {
        switch (name) {
        case "cyan":
            return Theme.cyan;
        case "magenta":
            return Theme.magenta;
        case "yellow":
            return Theme.yellow;
        case "fg":
            return Theme.fg;
        default:
            return Theme.fgDim;
        }
    }

    Component {
        id: logoModule
        LogoModule {}
    }

    Component {
        id: clockModule
        ClockModule {}
    }

    Component {
        id: separatorModule
        SeparatorModule {}
    }

    Component {
        id: workspaceDisplayModule
        WorkspaceDisplay {}
    }

    Component {
        id: batteryModule
        BatteryModule {}
    }

    Component {
        id: wifiModule
        WifiModule {}
    }

    Component {
        id: settingsModule
        SettingsModule {}
    }

    Component {
        id: controlCenterModule
        ControlCenterModule {}
    }
}
