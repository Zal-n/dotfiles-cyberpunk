import QtQuick
import QtQuick.Controls
import ".."

Slider {
    id: control
    property color accentColor: Theme.cyan
    value: 0.8

    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + control.availableHeight / 2 - height / 2
        implicitWidth: 200
        implicitHeight: 6
        width: control.availableWidth
        height: implicitHeight
        color: Theme.surface

        Rectangle {
            width: control.visualPosition * parent.width
            height: parent.height
            color: control.accentColor
        }
    }

    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + control.availableHeight / 2 - height / 2
        implicitWidth: 16
        implicitHeight: 16
        color: Theme.bg
        border.color: control.accentColor
        border.width: 2
    }
}