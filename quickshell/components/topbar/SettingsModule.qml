import QtQuick
import ".."

Rectangle {
    property var topbar
    property var moduleConfig: ({})
    readonly property var preset: topbar ? topbar.modulePreset(moduleConfig) : ({})

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
        onClicked: topbar.settingsToggled()
    }
}
