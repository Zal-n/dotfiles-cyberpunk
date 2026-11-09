import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."

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
                    source: Qt.resolvedUrl("./" + bar.moduleSource(modelData.id))
                    onStatusChanged: {
                        if (status === Loader.Ready) {
                            item.topbar = bar;
                            item.moduleConfig = moduleConfig;
                        }
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
                    source: Qt.resolvedUrl("./" + bar.moduleSource(modelData.id))
                    onStatusChanged: {
                        if (status === Loader.Ready) {
                            item.topbar = bar;
                            item.moduleConfig = moduleConfig;
                        }
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
                    source: Qt.resolvedUrl("./" + bar.moduleSource(modelData.id))
                    onStatusChanged: {
                        if (status === Loader.Ready) {
                            item.topbar = bar;
                            item.moduleConfig = moduleConfig;
                        }
                    }
                }
            }
        }
    }

    function modulePreset(module) {
        return bar.presets[module.id]?.[module.preset ?? "default"] ?? ({});
    }

    function moduleSource(moduleId) {
        switch (moduleId) {
        case "logo":
            return "topbar/LogoModule.qml";
        case "clock":
            return "topbar/ClockModule.qml";
        case "settings":
            return "topbar/SettingsModule.qml";
        case "controlCenter":
            return "topbar/ControlCenterModule.qml";
        case "separator":
            return "topbar/SeparatorModule.qml";
        case "workspaceDisplay":
            return "topbar/WorkspaceDisplay.qml";
        case "battery":
            return "topbar/BatteryModule.qml";
        case "wifi":
            return "topbar/WifiModule.qml";
        default:
            return "";
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
}
