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
                    implicitWidth: item ? item.implicitWidth : 0
                    implicitHeight: item ? item.implicitHeight : 0
                    Layout.preferredWidth: implicitWidth
                    Layout.preferredHeight: implicitHeight
                    sourceComponent: bar.moduleComponent(modelData.id)
                    onLoaded: {
                        item.topbar = bar;
                        item.moduleConfig = moduleConfig;
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
                    implicitWidth: item ? item.implicitWidth : 0
                    implicitHeight: item ? item.implicitHeight : 0
                    Layout.preferredWidth: implicitWidth
                    Layout.preferredHeight: implicitHeight
                    sourceComponent: bar.moduleComponent(modelData.id)
                    onLoaded: {
                        item.topbar = bar;
                        item.moduleConfig = moduleConfig;
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
                    implicitWidth: item ? item.implicitWidth : 0
                    implicitHeight: item ? item.implicitHeight : 0
                    Layout.preferredWidth: implicitWidth
                    Layout.preferredHeight: implicitHeight
                    sourceComponent: bar.moduleComponent(modelData.id)
                    onLoaded: {
                        item.topbar = bar;
                        item.moduleConfig = moduleConfig;
                    }
                }
            }
        }
    }

    function modulePreset(module) {
        return bar.presets[module.id]?.[module.preset ?? "default"] ?? ({});
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
