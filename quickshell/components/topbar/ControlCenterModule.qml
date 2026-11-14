import QtQuick
import Quickshell
import "../.."

Rectangle {
    property var topbar
    property var moduleConfig: ({})
    readonly property var preset: topbar ? topbar.modulePreset(moduleConfig) : ({})

    width: 100
    height: 26
    color: Theme.surface
    border.color: Theme.magenta
    border.width: 1

    Text {
        anchors.centerIn: parent
        text: parent.preset.text ?? "CTRL"
        color: Theme.magenta
        font.family: Theme.fontFamily
        font.pixelSize: 11
        font.bold: true
    }
    MouseArea {
        anchors.fill: parent
        onClicked: topbar.controlCenterToggled()
    }
}
