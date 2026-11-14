import QtQuick
import "../.."

Text {
    property var topbar
    property var moduleConfig: ({})
    readonly property var preset: topbar ? topbar.modulePreset(moduleConfig) : ({})

    text: preset.text ?? "//"
    color: Theme.fgDim
    font.family: Theme.fontFamily
    font.bold: true
}
