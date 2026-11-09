import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import ".."

Row {
    id: battery
    property var topbar
    property var moduleConfig: ({})
    readonly property var preset: topbar ? topbar.modulePreset(moduleConfig) : ({})
    property int capacity: -1
    property string status: "Unknown"
    property bool popupOpen: false
    readonly property bool isCharging: status.trim().toLowerCase() === "charging"
    spacing: 4

    Process {
        id: batteryProcess
        command: [
            "sh", "-c",
            "device=${1:-BAT0}; " +
            "printf '%s\\n' \"$(cat /sys/class/power_supply/$device/capacity 2>/dev/null || echo -1)\" " +
            "\"$(cat /sys/class/power_supply/$device/status 2>/dev/null || echo Unknown)\"",
            "battery", battery.moduleConfig.device ?? "BAT0"
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split(/\r?\n/);
                var parsedCapacity = Number.parseInt(lines[0], 10);
                battery.capacity = Number.isFinite(parsedCapacity) ? parsedCapacity : -1;
                battery.status = (lines[1] ?? "Unknown").trim();
                batteryRefresh.restart();
            }
        }
        onRunningChanged: {
            if (!running) {
                batteryRefresh.restart();
            }
        }
    }

    Timer {
        id: batteryRefresh
        interval: battery.preset.refreshInterval ?? 5000
        repeat: true
        running: true
        onTriggered: {
            if (!batteryProcess.running) {
                batteryProcess.running = true;
            }
        }
    }

    Text {
        readonly property var iconSet: battery.preset.icons ?? ({})
        readonly property string level: {
            if (battery.capacity < 0) return "unknown";
            if (battery.isCharging) return "charging";
            if (battery.capacity >= 80) return "full";
            if (battery.capacity >= 40) return "high";
            if (battery.capacity >= 20) return "medium";
            if (battery.capacity >= 10) return "low";
            return "critical";
        }
        visible: battery.preset.style === "icon-label" && battery.preset.showIcon !== false
        text: iconSet[level] ?? iconSet.unknown ?? "󰁹"
        color: battery.isCharging
            ? battery.topbar.presetColor(battery.preset.chargingColor)
            : battery.topbar.presetColor(battery.preset.normalColor)
        font.family: Theme.fontFamily
        font.pixelSize: battery.preset.fontSize ?? 13
    }

    Text {
        visible: battery.capacity >= 0
        text: {
            var percentage = battery.capacity;
            var format = battery.preset.format ?? "{percentage}%";
            return format.replace("{percentage}", percentage);
        }
        color: battery.isCharging
            ? battery.topbar.presetColor(battery.preset.chargingColor)
            : battery.topbar.presetColor(battery.preset.normalColor)
        font.family: Theme.fontFamily
        font.pixelSize: battery.preset.fontSize ?? 13
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: battery.popupOpen = !battery.popupOpen
    }

    PanelWindow {
        visible: battery.popupOpen
        WlrLayershell.layer: WlrLayer.Overlay
        anchors.top: true
        anchors.right: true
        margins.top: Theme.barHeight + 8
        margins.right: 16
        implicitWidth: 260
        implicitHeight: 100
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        Item {
            anchors.fill: parent

            Canvas {
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d");
                    var cut = Theme.cornerCutSize;
                    ctx.clearRect(0, 0, width, height);
                    ctx.beginPath();
                    ctx.moveTo(0, 0);
                    ctx.lineTo(width, 0);
                    ctx.lineTo(width, height);
                    ctx.lineTo(cut, height);
                    ctx.lineTo(0, height - cut);
                    ctx.closePath();
                    ctx.fillStyle = Theme.bg;
                    ctx.fill();
                    ctx.lineWidth = 1;
                    ctx.strokeStyle = battery.isCharging ? Theme.yellow : Theme.cyan;
                    ctx.stroke();
                }
            }

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 6

                Text {
                    text: battery.isCharging ? "BATTERY // CHARGING" : "BATTERY // ON POWER"
                    color: battery.isCharging ? Theme.yellow : Theme.cyan
                    font.family: Theme.fontFamily
                    font.bold: true
                }
                Text {
                    text: battery.capacity >= 0
                        ? "CHARGE // " + battery.capacity + "%"
                        : "CHARGE // UNKNOWN"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
                Text {
                    text: battery.status.toUpperCase()
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: battery.popupOpen = false
            }
        }
    }
}
