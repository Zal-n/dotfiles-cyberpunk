import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../.."

Item {
    property bool powered: false
    property real gridWidth: 4
    property real gridHeight: 2
    readonly property bool compact: gridWidth <= 1 && gridHeight <= 1

    Process {
        id: bluetoothProcess
        command: [
            "sh", "-c",
            "command -v bluetoothctl >/dev/null 2>&1 || exit 0; bluetoothctl show"
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                powered = /Powered:\s+yes/i.test(text);
                refreshTimer.restart();
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 5000
        repeat: true
        running: true
        onTriggered: if (!bluetoothProcess.running) bluetoothProcess.running = true
    }

    ColumnLayout {
        visible: compact
        anchors.fill: parent
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "󰂯"
            color: powered ? Theme.magenta : Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: 24
        }
    }

    ColumnLayout {
        visible: !compact
        anchors.fill: parent
        spacing: 4
        Text {
            text: "BLUETOOTH"
            color: powered ? Theme.magenta : Theme.fgDim
            font.family: Theme.fontFamily
            font.bold: true
        }
        Text {
            text: powered ? "POWER // ON" : "POWER // OFF"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }
        Text {
            text: "CLICK TO TOGGLE"
            color: Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: 9
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.runInputCommand([
            "bluetoothctl", "power", powered ? "off" : "on"
        ])
    }
}
