import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."

PanelWindow {
    id: bar
    signal controlCenterToggled()
    signal settingsToggled()

    readonly property bool isHovered: mouseArea.containsMouse || cc.mouseArea.containsMouse

    WlrLayershell.layer: WlrLayer.Top

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 38
    color: Theme.bg

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        implicitHeight: 2
        color: Theme.cyan
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 12

        Text {
            text: "SYS // NIRI"
            color: Theme.cyan
            font.family: Theme.fontFamily
            font.bold: true
            font.pixelSize: 13
        }

        Item { Layout.fillWidth: true }

        Text {
            id: clockText
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
                    clockText.text = d.toLocaleTimeString(Qt.locale(), "hh:mm:ss") + " | " + d.toISOString().split('T')[0];
                }
            }
        }

        Item { Layout.fillWidth: true }

        // Settings Gomb
        Rectangle {
            Layout.preferredWidth: 30
            Layout.preferredHeight: 26
            color: Theme.surface
            border.color: Theme.cyan
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "⚙"
                color: Theme.cyan
                font.family: Theme.fontFamily
            }

            MouseArea {
                anchors.fill: parent
                onClicked: bar.settingsToggled()
            }
        }

        // Control Center Gomb
        Rectangle {
            Layout.preferredWidth: 100
            Layout.preferredHeight: 26
            color: Theme.surface
            border.color: Theme.magenta
            border.width: 1

            RowLayout {
                anchors.centerIn: parent
                spacing: 6
                Text { text: "CTRL"; color: Theme.fg; font.family: Theme.fontFamily; font.pixelSize: 11; font.bold: true }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                //onClicked: bar.controlCenterToggled()
                hoverEnabled: true
            }
            Timer {
                id: openTimer
                interval: 200
                repeat: false
                onTriggered: {
                    if (bar.isHovered) {
                        cc.visible = true
                    }
                }
            }

            Timer {
                id: closeTimer
                interval: 150
                repeat: false
                onTriggered: {
                    if (!bar.isHovered) {
                        cc.visible = false
                    }
                }
            }
        }
    }
}
