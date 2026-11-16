import QtQuick
import QtQuick.Layouts
import Quickshell
import "../.."
import "../../services"

Item {
    property var topbar: null
    property var wifi: topbar?.wifiModule
    property real gridWidth: 6
    property real gridHeight: 2
    readonly property bool compact: gridWidth <= 1 && gridHeight <= 1
    readonly property bool horizontal: gridHeight <= 1 && gridWidth >= 2

    Text {
        visible: compact
        anchors.centerIn: parent
        text: WifiController?.connected ? "󰤨" : "󰤭"
        color: WifiController?.connected ? Theme.cyan : Theme.magenta
        font.family: Theme.fontFamily
        font.pixelSize: 24
    }

    RowLayout {
        visible: horizontal
        anchors.fill: parent
        spacing: 8
        Text {
            text: WifiController?.connected ? "󰤨" : "󰤭"
            color: WifiController?.connected ? Theme.cyan : Theme.magenta
            font.family: Theme.fontFamily
            font.pixelSize: 24
        }
        Text {
            Layout.fillWidth: true
            text: WifiController?.connected ? WifiController.activeName : "OFFLINE"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 11
            elide: Text.ElideRight
        }
    }

    ColumnLayout {
        visible: !compact && !horizontal
        anchors.fill: parent
        spacing: 4
        Text {
            text: "WIFI"
            color: WifiController?.connected ? Theme.cyan : Theme.magenta
            font.family: Theme.fontFamily
            font.bold: true
        }
        Text {
            text: WifiController?.connected ? WifiController.activeName : "OFFLINE"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 11
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
        Text {
            text: WifiController?.radioEnabled ? "RADIO // ON" : "RADIO // OFF"
            color: Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: 10
        }
    }
    MouseArea {
        anchors.fill: parent
        onClicked: if (wifi) wifi.popupOpen = true
    }
}
