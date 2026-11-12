import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../.."

Item {
    property int windowCount: 0
    property real gridWidth: 8
    property real gridHeight: 2
    readonly property bool compact: gridWidth <= 1 && gridHeight <= 1

    Process {
        id: windowsProcess
        command: ["niri", "msg", "-j", "windows"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var windows = JSON.parse(text);
                    windowCount = Array.isArray(windows) ? windows.length : 0;
                } catch (e) {
                    windowCount = 0;
                }
                refreshTimer.restart();
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 3000
        repeat: true
        running: true
        onTriggered: if (!windowsProcess.running) windowsProcess.running = true
    }

    ColumnLayout {
        visible: compact
        anchors.fill: parent
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "󰣆"
            color: Theme.yellow
            font.family: Theme.fontFamily
            font.pixelSize: 24
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: windowCount
            color: Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: 9
        }
    }

    ColumnLayout {
        visible: !compact
        anchors.fill: parent
        spacing: 4
        Text {
            text: "BACKGROUND APPS"
            color: Theme.yellow
            font.family: Theme.fontFamily
            font.bold: true
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
        Text {
            text: windowCount + " WINDOWS // ACTIVE"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }
        /*Text {
            text: "APP MANAGEMENT // SOON"
            color: Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: 9
          }*/
    }
}
