import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."
import "../.."
import "."

Item {
    id: brightnessModule
    property real level: 0
    property real gridWidth: 8
    property real gridHeight: 2
    readonly property string layoutMode: layout.mode
    readonly property bool compact: layout.compact
    readonly property bool vertical: layout.vertical

    ModuleLayout {
        id: layout
        kind: "slider"
        gridWidth: brightnessModule.gridWidth
        gridHeight: brightnessModule.gridHeight
    }

    Process {
        id: brightnessProcess
        command: [
            "sh", "-c",
            "current=$(brightnessctl get 2>/dev/null || echo 0); " +
            "maximum=$(brightnessctl max 2>/dev/null || echo 1); " +
            "awk -v c=\"$current\" -v m=\"$maximum\" 'BEGIN { print c / m }'"
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var next = Number.parseFloat(text.trim());
                if (Number.isFinite(next)) level = Math.max(0, Math.min(1, next));
                refreshTimer.restart();
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 500
        repeat: true
        running: true
        onTriggered: if (!brightnessProcess.running) brightnessProcess.running = true
    }

    ColumnLayout {
        visible: compact
        anchors.fill: parent
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "󰃠"
            color: Theme.cyan
            font.family: Theme.fontFamily
            font.pixelSize: 24
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Math.round(level * 100) + "%"
            color: Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: 9
        }
    }

    ColumnLayout {
        visible: vertical
        anchors.fill: parent
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Math.round(level * 100) + "%"
            color: Theme.cyan
            font.family: Theme.fontFamily
            font.bold: true
            font.pixelSize: 9
        }
        QuickSlider {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: true
            Layout.preferredWidth: 24
            Layout.minimumHeight: 48
            verticalMode: true
            value: brightnessModule.level
            accentColor: Theme.cyan
            onMoved: root.runInputCommand(["brightnessctl", "set", Math.round(value * 100) + "%"])
        }
    }

    ColumnLayout {
        visible: !compact && !vertical
        anchors.fill: parent
        spacing: 4
        Text {
            text: "BRIGHTNESS // " + Math.round(level * 100) + "%"
            color: Theme.cyan
            font.family: Theme.fontFamily
            font.bold: true
        }
        QuickSlider {
            Layout.fillWidth: true
            value: brightnessModule.level
            accentColor: Theme.cyan
            onMoved: root.runInputCommand(["brightnessctl", "set", Math.round(value * 100) + "%"])
        }
    }
}
