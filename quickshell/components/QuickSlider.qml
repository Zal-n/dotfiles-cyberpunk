import QtQuick
import QtQuick.Controls
import ".."

Slider {
    id: control
    property color accentColor: Theme.cyan
    property bool verticalMode: false
    value: 0.8
    orientation: verticalMode ? Qt.Vertical : Qt.Horizontal
    implicitWidth: verticalMode ? 24 : 200
    implicitHeight: verticalMode ? 160 : 24

    background: Rectangle {
        x: control.verticalMode
            ? control.leftPadding + control.availableWidth / 2 - width / 2
            : control.leftPadding
        y: control.verticalMode
            ? control.topPadding
            : control.topPadding + control.availableHeight / 2 - height / 2
        implicitWidth: 200
        implicitHeight: 6
        width: control.verticalMode ? implicitHeight : control.availableWidth
        height: control.verticalMode ? control.availableHeight : implicitHeight
        color: Theme.surface

        Rectangle {
            x: 0
            y: control.verticalMode ? control.visualPosition * parent.height : 0
            width: control.verticalMode ? parent.width : control.visualPosition * parent.width
            height: control.verticalMode ? (1 - control.visualPosition) * parent.height : parent.height
            color: control.accentColor
        }
    }

    handle: Rectangle {
        x: control.verticalMode
            ? control.leftPadding + control.availableWidth / 2 - width / 2
            : control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.verticalMode
            ? control.topPadding + control.visualPosition * (control.availableHeight - height)
            : control.topPadding + control.availableHeight / 2 - height / 2
        implicitWidth: 16
        implicitHeight: 16
        color: Theme.bg
        border.color: control.accentColor
        border.width: 2
    }
}