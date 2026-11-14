import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../.."

Item {
    property real volume: -1
    property bool muted: false
    property real gridWidth: 4
    property real gridHeight: 2
    readonly property bool compact: gridWidth <= 1 && gridHeight <= 1
    readonly property bool horizontal: gridHeight <= 1 && gridWidth >= 2

    Process {
        id: micProcess
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var match = text.match(/Volume:\s+([0-9.]+)(?:\s+\[MUTED\])?/);
                volume = match ? Number.parseFloat(match[1]) : -1;
                muted = text.indexOf("[MUTED]") !== -1;
                refreshTimer.restart();
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 500
        repeat: true
        running: true
        onTriggered: if (!micProcess.running) micProcess.running = true
    }

    ColumnLayout {
        visible: compact
        anchors.fill: parent
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: muted ? "󰍭" : "󰍬"
            color: muted ? Theme.yellow : Theme.cyan
            font.family: Theme.fontFamily
            font.pixelSize: 24
        }
    }

    RowLayout {
        visible: horizontal
        anchors.fill: parent
        Text {
            text: muted ? "󰍭" : "󰍬"
            color: muted ? Theme.yellow : Theme.cyan
            font.family: Theme.fontFamily
            font.pixelSize: 24
        }
        ColumnLayout {
            Layout.fillWidth: true
            Text {
                text: muted ? "MUTED" : "MICROPHONE"
                color: muted ? Theme.yellow : Theme.cyan
                font.family: Theme.fontFamily
                font.bold: true
                font.pixelSize: 10
            }
            Text {
                text: volume >= 0 ? Math.round(volume * 100) + "%" : "UNKNOWN"
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
        }
    }

    ColumnLayout {
        visible: !compact && !horizontal
        anchors.fill: parent
        spacing: 4
        Text {
            text: "MICROPHONE"
            color: muted ? Theme.yellow : Theme.cyan
            font.family: Theme.fontFamily
            font.bold: true
        }
        Text {
            text: muted ? "MUTED" : volume >= 0 ? Math.round(volume * 100) + "%" : "UNKNOWN"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 12
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
            "wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"
        ])
    }
}
