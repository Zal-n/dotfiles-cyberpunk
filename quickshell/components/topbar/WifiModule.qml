import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import ".."

Item {
    id: wifi
    property var topbar
    property var moduleConfig: ({})
    readonly property var preset: topbar ? topbar.modulePreset(moduleConfig) : ({})
    property bool connected: false
    property string ssid: ""
    property int signal: 0
    property bool popupOpen: false
    width: wifiIcon.width
    height: wifiIcon.height

    Process {
        id: wifiProcess
        command: [
            "sh", "-c",
            "device=$(nmcli -t -f DEVICE,TYPE,STATE device 2>/dev/null | " +
            "awk -F: '$2 == \"wifi\" && $3 == \"connected\" { print $1; exit }'); " +
            "if [ -z \"$device\" ]; then exit 0; fi; " +
            "nmcli -t -f GENERAL.CONNECTION device show \"$device\" 2>/dev/null | " +
            "sed -n 's/^GENERAL.CONNECTION://p'; " +
            "nmcli -t -f IN-USE,SIGNAL dev wifi 2>/dev/null | " +
            "awk -F: '$1 == \"*\" { print $2; exit }'"
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split(/\r?\n/);
                wifi.connected = lines.length >= 1 && lines[0].length > 0;
                wifi.ssid = wifi.connected ? lines[0] : "";
                wifi.signal = wifi.connected && lines.length >= 2
                    ? Number.parseInt(lines[1], 10) || 0
                    : 0;
            }
        }
        onRunningChanged: {
            if (!running) {
                wifiRefresh.restart();
            }
        }
    }

    Timer {
        id: wifiRefresh
        interval: 5000
        repeat: true
        running: true
        onTriggered: {
            if (!wifiProcess.running) {
                wifiProcess.running = true;
            }
        }
    }

    Text {
        id: wifiIcon
        text: wifi.connected
            ? (wifi.preset.icons?.connected ?? "󰤨")
            : (wifi.preset.icons?.disconnected ?? "󰤭")
        color: wifi.connected
            ? wifi.topbar.presetColor(wifi.preset.connectedColor)
            : wifi.topbar.presetColor(wifi.preset.disconnectedColor)
        font.family: Theme.fontFamily
        font.pixelSize: wifi.preset.fontSize ?? 16

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: wifi.popupOpen = !wifi.popupOpen
        }
    }

    PanelWindow {
        visible: wifi.popupOpen
        WlrLayershell.layer: WlrLayer.Overlay
        anchors.top: true
        anchors.right: true
        margins.top: Theme.barHeight + 8
        margins.right: 16
        implicitWidth: 260
        implicitHeight: 100
        color: "transparent"

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
                    ctx.strokeStyle = Theme.cyan;
                    ctx.stroke();
                }
            }

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 6

                Text {
                    text: wifi.connected ? "WIFI // CONNECTED" : "WIFI // OFFLINE"
                    color: wifi.connected ? Theme.cyan : Theme.magenta
                    font.family: Theme.fontFamily
                    font.bold: true
                }
                Text {
                    text: wifi.connected
                        ? wifi.ssid + " // " + wifi.signal + "%"
                        : "NO ACTIVE NETWORK"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
                Text {
                    text: "NETWORK CONTROLS // SOON"
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: wifi.popupOpen = false
            }
        }
    }
}
