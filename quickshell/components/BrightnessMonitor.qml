import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: monitor
    property var toast: null
    property int level: -1
    property bool initialized: false

    Process {
        id: brightnessProcess
        command: [
            "sh", "-c",
            "current=$(brightnessctl get 2>/dev/null || echo -1); " +
            "maximum=$(brightnessctl max 2>/dev/null || echo -1); " +
            "printf '%s\\n%s\\n' \"$current\" \"$maximum\""
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split(/\r?\n/);
                var current = Number.parseInt(lines[0], 10);
                var maximum = Number.parseInt(lines[1], 10);
                if (!Number.isFinite(current) || !Number.isFinite(maximum) || maximum <= 0) {
                    return;
                }
                var nextLevel = Math.round(current / maximum * 100);
                if (monitor.initialized && nextLevel !== monitor.level) {
                    monitor.toast?.showToast("BRIGHTNESS // " + nextLevel + "%", false, null, 900);
                }
                monitor.level = nextLevel;
                monitor.initialized = true;
                refreshTimer.restart();
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 150
        repeat: true
        running: true
        onTriggered: if (!brightnessProcess.running) brightnessProcess.running = true
    }
}
