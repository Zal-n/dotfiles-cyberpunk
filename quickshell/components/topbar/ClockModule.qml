import QtQuick
import ".."

Text {
    property var topbar
    property var moduleConfig: ({})
    readonly property var preset: topbar ? topbar.modulePreset(moduleConfig) : ({})

    color: Theme.yellow
    font.family: Theme.fontFamily
    font.bold: true
    font.pixelSize: 13

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var d = new Date();
            var value = d.toLocaleTimeString(Qt.locale(), parent.preset.timeFormat ?? "HH:mm");
            if (parent.preset.showDate === true) {
                value += " | " + d.toISOString().split('T')[0];
            }
            parent.text = value;
        }
    }
}
