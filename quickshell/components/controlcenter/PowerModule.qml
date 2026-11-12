import QtQuick
import QtQuick.Layouts
import "../.."

Item {
    property real gridWidth: 8
    property real gridHeight: 2
    readonly property bool compact: gridWidth <= 1 && gridHeight <= 1

    Text {
        visible: compact
        anchors.centerIn: parent
        text: "⏻"
        color: Theme.magenta
        font.family: Theme.fontFamily
        font.pixelSize: 24
    }

    RowLayout {
        visible: !compact
        anchors.fill: parent
        spacing: 6

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.surfaceAccent
            Text {
                anchors.centerIn: parent
                text: "RESTART"
                color: Theme.magenta
                font.family: Theme.fontFamily
                font.bold: true
                font.pixelSize: 10
            }
            MouseArea {
                anchors.fill: parent
                onClicked: root.runSystemAction("restart")
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.magenta
            Text {
                anchors.centerIn: parent
                text: "POWER OFF"
                color: Theme.bg
                font.family: Theme.fontFamily
                font.bold: true
                font.pixelSize: 10
            }
            MouseArea {
                anchors.fill: parent
                onClicked: root.runSystemAction("poweroff")
            }
        }
    }
}
