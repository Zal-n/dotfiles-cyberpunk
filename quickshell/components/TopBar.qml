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
                    sourceComponent: bar.moduleComponent(modelData.id)
                    onLoaded: item.moduleConfig = moduleConfig
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
                    sourceComponent: bar.moduleComponent(modelData.id)
                    onLoaded: item.moduleConfig = moduleConfig
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
                    sourceComponent: bar.moduleComponent(modelData.id)
                    onLoaded: item.moduleConfig = moduleConfig
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
        default:
            return null;
        }
    }

    Component {
        id: logoModule
        Text {
            property var moduleConfig: ({})
            readonly property var preset: bar.modulePreset(moduleConfig)
            visible: moduleConfig.visible !== false
            text: preset.text ?? ""
            color: Theme.cyan
            font.family: Theme.fontFamily
            font.bold: true
            font.pixelSize: preset.fontSize ?? 13
        }
    }

    Component {
        id: clockModule
        Text {
            property var moduleConfig: ({})
            readonly property var preset: bar.modulePreset(moduleConfig)
            color: Theme.yellow
            font.family: Theme.fontFamily
            font.bold: true
            font.pixelSize: 13

            Timer {
                interval: 1000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: {
                    var d = new Date();
                    var value;
                    if (parent.preset.timeFormat)
                    {
                        value = d.toLocaleTimeString(Qt.locale(), parent.preset.timeFormat);
                    }
                    if (parent.preset.showDate === true) {
                        if(parent.preset.timeFormat) value += " | ";
                        value += d.toISOString().split('T')[0];
                    }
                    parent.text = value;
                }
            }
        }
    }

    Component {
        id: separatorModule
        Text {
            property var moduleConfig: ({})
            readonly property var preset: bar.modulePreset(moduleConfig)
            text: preset.text ?? "//"
            color: Theme.fgDim
            font.family: Theme.fontFamily
            font.bold: true
        }
    }

    Component {
        id: settingsModule
        Rectangle {
            property var moduleConfig: ({})
            readonly property var preset: bar.modulePreset(moduleConfig)
            width: 30
            height: 26
            color: Theme.surface
            border.color: Theme.cyan
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: parent.preset.text ?? "⚙"
                color: Theme.cyan
                font.family: Theme.fontFamily
                font.pixelSize: 20
            }
            MouseArea {
                anchors.fill: parent
                onClicked: bar.settingsToggled()
            }
        }
    }

    Component {
        id: controlCenterModule
        Rectangle {
            property var moduleConfig: ({})
            readonly property var preset: bar.modulePreset(moduleConfig)
            width: 100
            height: 26
            color: Theme.surface
            border.color: Theme.magenta
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: parent.preset.text ?? "CTRL"
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.bold: true
            }
            MouseArea {
                anchors.fill: parent
                onClicked: bar.controlCenterToggled()
            }
        }
    }
}
