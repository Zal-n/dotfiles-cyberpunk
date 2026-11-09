import QtQuick
import "../.."

Text {
    property var topbar
    property var moduleConfig: ({})
    readonly property var preset: topbar ? topbar.modulePreset(moduleConfig) : ({})

    visible: moduleConfig.visible !== false
    text: preset.text ?? ""
    color: Theme.cyan
    font.family: Theme.fontFamily
    font.bold: true
    font.pixelSize: preset.fontSize ?? 13
}
