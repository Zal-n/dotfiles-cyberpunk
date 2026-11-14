import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."
import "../.."
import "."

Item {
    id: audioModule
    property var topbar: null
    property var audio: topbar?.audioModule
    property real gridWidth: 6
    property real gridHeight: 2
    readonly property string layoutMode: layout.mode
    readonly property bool compact: layout.compact
    readonly property bool vertical: layout.vertical

    ModuleLayout {
        id: layout
        kind: "slider"
        gridWidth: audioModule.gridWidth
        gridHeight: audioModule.gridHeight
    }

    ColumnLayout {
        visible: compact
        anchors.fill: parent
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: audio?.muted ? "󰝟" : "󰕾"
            color: audio?.muted ? Theme.yellow : Theme.magenta
            font.family: Theme.fontFamily
            font.pixelSize: 24
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: audio && audio.volume >= 0 ? Math.round(audio.volume * 100) + "%" : "?"
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
            text: audio?.muted ? "MUTE" : "AUDIO"
            color: Theme.magenta
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
            value: audio?.volume >= 0 ? audio.volume : 0
            enabled: audio?.volume >= 0
            accentColor: Theme.magenta
            onMoved: root.runInputCommand([
                "wpctl", "set-volume", audio?.sink ?? "@DEFAULT_AUDIO_SINK@",
                value.toFixed(2)
            ])
        }
    }

    ColumnLayout {
        visible: !compact && !vertical
        anchors.fill: parent
        spacing: 4
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "AUDIO"
                color: Theme.magenta
                font.family: Theme.fontFamily
                font.bold: true
            }
            Item { Layout.fillWidth: true }
            Text {
                text: audio?.muted ? "MUTED" : audio && audio.volume >= 0
                    ? Math.round(audio.volume * 100) + "%" : "UNKNOWN"
                color: Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
        }
        QuickSlider {
            Layout.fillWidth: true
            value: audio?.volume >= 0 ? audio.volume : 0
            enabled: audio?.volume >= 0
            accentColor: Theme.magenta
            onMoved: root.runInputCommand([
                "wpctl", "set-volume", audio?.sink ?? "@DEFAULT_AUDIO_SINK@",
                value.toFixed(2)
            ])
        }
        Text {
            text: "CLICK TO TOGGLE MUTE"
            color: Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: 9
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: root.runInputCommand([
            "wpctl", "set-mute", audio?.sink ?? "@DEFAULT_AUDIO_SINK@", "toggle"
        ])
    }
}
