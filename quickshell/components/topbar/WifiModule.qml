import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../.."

Item {
    id: wifi
    property var topbar
    property var moduleConfig: ({})
    readonly property var preset: topbar ? topbar.modulePreset(moduleConfig) : ({})
    property bool connected: false
    property string ssid: ""
    property int signal: 0
    property bool radioEnabled: false
    property var networks: []
    property var savedNetworks: []
    property bool popupOpen: false
    readonly property string popupKey: "wifi"
    readonly property int popupHeight: 100
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

    Process {
        id: radioProcess
        command: ["nmcli", "radio", "wifi"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                wifi.radioEnabled = text.trim() === "enabled";
                if (wifi.radioEnabled && wifi.popupOpen) scanNetworks();
            }
        }
    }

    Process {
        id: toggleRadioProcess
        command: ["nmcli", "radio", "wifi", wifi.radioEnabled ? "off" : "on"]
        onExited: {
            radioProcess.running = true;
            wifiProcess.running = true;
            if (wifi.radioEnabled) scanNetworks();
        }
    }

    Process {
        id: scanProcess
        command: [
            "nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY",
            "device", "wifi", "list", "--rescan", "yes"
        ]
        stdout: StdioCollector {
            onStreamFinished: wifi.networks = parseNetworks(text)
        }
    }

    Process {
        id: savedProcess
        command: ["nmcli", "-t", "-f", "NAME,TYPE,802-11-wireless.ssid", "connection", "show"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: wifi.savedNetworks = parseSavedNetworks(text)
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

    function parseNetworks(output) {
        var result = [];
        var seen = ({});
        var lines = output.trim().split(/\r?\n/);
        for (var i = 0; i < lines.length; i++) {
            if (!lines[i]) continue;
            var fields = [];
            var field = "";
            var escaped = false;
            for (var j = 0; j < lines[i].length; j++) {
                var character = lines[i][j];
                if (escaped) {
                    field += character;
                    escaped = false;
                } else if (character === "\\") {
                    escaped = true;
                } else if (character === ":") {
                    fields.push(field);
                    field = "";
                } else {
                    field += character;
                }
            }
            fields.push(field);
            var networkName = fields[1] ?? "";
            var signalStrength = Number.parseInt(fields[2] ?? "0", 10) || 0;
            if (!networkName || signalStrength <= 0 || seen[networkName]) continue;
            seen[networkName] = true;
            result.push({
                "ssid": networkName,
                "signal": signalStrength,
                "security": fields[3] ?? "",
                "connected": fields[0] === "*",
                "saved": isSaved(networkName)
            });
        }
        result.sort(function(left, right) {
            return right.signal - left.signal;
        });
        return result;
    }

    function displayNetworks() {
        var result = networks.slice();
        var visible = ({});
        result.forEach(function(network) {
            visible[network.ssid] = true;
        });
        savedNetworks.forEach(function(connection) {
            if (!connection.ssid || visible[connection.ssid]) return;
            result.push({
                "ssid": connection.ssid,
                "signal": 0,
                "security": "saved",
                "connected": false,
                "saved": true,
                "unavailable": true
            });
        });
        result.sort(function(left, right) {
            if (left.unavailable !== right.unavailable) {
                return left.unavailable ? 1 : -1;
            }
            return right.signal - left.signal;
        });
        return result;
    }

    function parseSavedNetworks(output) {
        var result = [];
        var lines = output.trim().split(/\r?\n/);
        for (var i = 0; i < lines.length; i++) {
            if (!lines[i]) continue;
            var fields = [];
            var field = "";
            var escaped = false;
            for (var j = 0; j < lines[i].length; j++) {
                var character = lines[i][j];
                if (escaped) {
                    field += character;
                    escaped = false;
                } else if (character === "\\") {
                    escaped = true;
                } else if (character === ":") {
                    fields.push(field);
                    field = "";
                } else {
                    field += character;
                }
            }
            fields.push(field);
            if (fields[1] !== "802-11-wireless") continue;
            result.push({
                "name": fields[0] ?? "",
                "ssid": fields[2] || fields[0] || ""
            });
        }
        return result;
    }

    function isSaved(networkName) {
        return savedNetworks.some(function(connection) {
            return connection.ssid === networkName;
        });
    }

    function toggleRadio() {
        if (!toggleRadioProcess.running) toggleRadioProcess.running = true;
    }

    function scanNetworks() {
        if (!radioEnabled || scanProcess.running) return;
        scanProcess.running = true;
    }

    function refreshSavedNetworks() {
        if (!savedProcess.running) savedProcess.running = true;
    }

    function refreshStatus() {
        if (!wifiProcess.running) wifiProcess.running = true;
        if (!radioProcess.running) radioProcess.running = true;
        refreshSavedNetworks();
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
            onClicked: wifi.topbar.togglePopup(wifi)
        }
    }

}
