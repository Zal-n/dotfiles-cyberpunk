pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    // --- Public Reactive State ---
    property bool available: true
    property bool powered: false
    property bool discovering: false
    property bool popupOpen: false

    property var devices: []              // Full sorted list: connected -> paired -> discovered
    property var connectedDevices: []     // Subset of devices currently connected
    readonly property int connectedCount: connectedDevices.length
    readonly property string primaryDeviceName: connectedDevices.length > 0
        ? connectedDevices[0].name
        : ""

    property string busyMac: ""           // MAC address currently connecting/pairing/removing
    property string statusMessage: ""
    property bool statusIsError: false

    // --- 1. Event-Driven BlueZ Monitor (Zero Idle Polling) ---
    // Interactive bluetoothctl session stays open and prints [CHG], [NEW], [DEL] events live
    Process {
        id: monitorProcess
        command: ["bluetoothctl"]
        running: true
        stdinEnabled: true
        stdout: SplitParser {
            onRead: line => {
                // Strip ANSI color escape sequences emitted by bluetoothctl
                var clean = line.replace(/\x1b\[[0-9;]*[a-zA-Z]/g, "").trim();
                if (!clean) return;

                if (clean.indexOf("Powered:") !== -1
                        || clean.indexOf("Discovering:") !== -1
                        || clean.indexOf("Connected:") !== -1
                        || clean.indexOf("Paired:") !== -1
                        || clean.indexOf("Battery Percentage:") !== -1
                        || clean.indexOf("[NEW] Device") !== -1
                        || clean.indexOf("[DEL] Device") !== -1) {
                    eventDebounce.restart();
                }
            }
        }
        onExited: function(exitCode) {
            if (exitCode === 127) {
                root.available = false;
                return;
            }
            monitorRestartTimer.start();
        }
    }

    Timer {
        id: eventDebounce
        interval: 250
        repeat: false
        onTriggered: root.refreshAll()
    }

    Timer {
        id: monitorRestartTimer
        interval: 2000
        repeat: false
        onTriggered: monitorProcess.running = true
    }

    // Auto-stop discovery after 15s when popup is open so radio doesn't stay in scan mode
    Timer {
        id: scanTimeoutTimer
        interval: 15000
        repeat: false
        onTriggered: root.stopScan()
    }

    // --- 2. Controller & Device State Queries ---
    Process {
        id: controllerStateProcess
        command: ["bluetoothctl", "show"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.indexOf("No default controller available") !== -1) {
                    root.available = false;
                    root.powered = false;
                    root.discovering = false;
                    root.devices = [];
                    root.connectedDevices = [];
                    return;
                }
                root.available = true;
                root.powered = /Powered:\s+yes/i.test(text);
                root.discovering = /Discovering:\s+yes/i.test(text);

                if (root.powered) {
                    if (!deviceListProcess.running) deviceListProcess.running = true;
                } else {
                    root.devices = [];
                    root.connectedDevices = [];
                }
            }
        }
    }

    // Queries all known devices + detailed info (Connected, Paired, Trusted, Icon, Battery)
    Process {
        id: deviceListProcess
        command: [
            "sh", "-c",
            "bluetoothctl devices | awk '/^Device / { print $2 }' | while read -r mac; do " +
            "  echo \"===DEVICE===$mac\"; " +
            "  bluetoothctl info \"$mac\"; " +
            "done"
        ]
        stdout: StdioCollector {
            onStreamFinished: root._parseDevicesBlock(text)
        }
    }

    // --- 3. User Actions ---
    Process {
        id: powerProcess
        property bool targetState: false
        command: ["bluetoothctl", "power", targetState ? "on" : "off"]
        onExited: function(exitCode) {
            if (exitCode === 0) {
                root.powered = targetState;
                root.refreshAll();
            } else {
                root._setStatus("POWER TOGGLE FAILED", true);
            }
        }
    }

    Process {
        id: scanProcess
        property bool enable: true
        command: ["bluetoothctl", "--timeout", "15", "scan", enable ? "on" : "off"]
        onRunningChanged: {
            if (running && enable) {
                root.discovering = true;
                scanTimeoutTimer.restart();
            } else if (!running) {
                root.discovering = false;
            }
        }
    }

    Process {
        id: deviceActionProcess
        property string action: ""   // "connect" | "disconnect" | "pair" | "remove"
        property string mac: ""
        command: {
            if (action === "pair") {
                return [
                    "sh", "-c",
                    "bluetoothctl pair \"$1\" && bluetoothctl trust \"$1\" && bluetoothctl connect \"$1\"",
                    "bt-pair", mac
                ];
            }
            return ["bluetoothctl", action, mac];
        }
        stdout: StdioCollector { id: actionStdout }
        stderr: StdioCollector { id: actionStderr }
        onExited: function(exitCode) {
            var finishedMac = mac;
            var finishedAction = action;
            root.busyMac = "";
            if (exitCode === 0) {
                root._setStatus(finishedAction.toUpperCase() + " // OK", false);
                root.refreshAll();
            } else {
                var raw = (actionStderr.text || actionStdout.text || "").trim();
                var lines = raw.split(/\r?\n/);
                var lastLine = lines.length > 0 ? lines[lines.length - 1] : "ACTION FAILED";
                root._setStatus(lastLine.toUpperCase(), true);
                root.refreshAll();
            }
        }
    }

    // --- Public API ---
    function refreshAll() {
        if (!controllerStateProcess.running) controllerStateProcess.running = true;
    }

    function togglePower() {
        if (!available || powerProcess.running) return;
        powerProcess.targetState = !powered;
        powerProcess.running = true;
    }

    function startScan() {
        if (!powered || scanProcess.running) return;
        scanProcess.enable = true;
        scanProcess.running = true;
    }

    function stopScan() {
        if (scanProcess.running) {
            scanProcess.running = false;
        }
        discovering = false;
    }

    function toggleDevice(device) {
        if (!device || busyMac.length > 0) return;
        clearStatus();
        busyMac = device.mac;
        deviceActionProcess.mac = device.mac;
        if (device.connected) {
            deviceActionProcess.action = "disconnect";
        } else if (device.paired) {
            deviceActionProcess.action = "connect";
        } else {
            deviceActionProcess.action = "pair";
        }
        deviceActionProcess.running = true;
    }

    function removeDevice(device) {
        if (!device || busyMac.length > 0) return;
        clearStatus();
        busyMac = device.mac;
        deviceActionProcess.mac = device.mac;
        deviceActionProcess.action = "remove";
        deviceActionProcess.running = true;
    }

    function clearStatus() {
        statusMessage = "";
        statusIsError = false;
    }

    // --- Internal Parsing ---
    function _setStatus(msg, isError) {
        statusMessage = msg;
        statusIsError = isError;
    }

    function _parseDevicesBlock(output) {
        var chunks = output.split("===DEVICE===");
        var parsed = [];
        var connected = [];

        for (var i = 1; i < chunks.length; i++) {
            var lines = chunks[i].trim().split(/\r?\n/);
            if (lines.length === 0) continue;

            var mac = lines[0].trim();
            var name = "";
            var alias = "";
            var icon = "bluetooth";
            var paired = false;
            var trusted = false;
            var isConnected = false;
            var battery = -1;

            for (var j = 1; j < lines.length; j++) {
                var line = lines[j].trim();
                if (line.startsWith("Name:")) {
                    name = line.slice(5).trim();
                } else if (line.startsWith("Alias:")) {
                    alias = line.slice(6).trim();
                } else if (line.startsWith("Icon:")) {
                    icon = line.slice(5).trim();
                } else if (line.startsWith("Paired:")) {
                    paired = /yes/i.test(line);
                } else if (line.startsWith("Trusted:")) {
                    trusted = /yes/i.test(line);
                } else if (line.startsWith("Connected:")) {
                    isConnected = /yes/i.test(line);
                } else if (line.startsWith("Battery Percentage:")) {
                    // Format: "Battery Percentage: 0x55 (85)"
                    var batMatch = line.match(/\((\d+)\)/);
                    if (batMatch) battery = Number.parseInt(batMatch[1], 10);
                }
            }

            var displayName = alias || name || mac;
            // Filter out unnamed raw BLE beacons unless already paired/connected
            if (!alias && !name && !paired && !isConnected) continue;

            var item = {
                "mac": mac,
                "name": displayName,
                "icon": icon,
                "paired": paired,
                "trusted": trusted,
                "connected": isConnected,
                "battery": battery
            };
            parsed.push(item);
            if (isConnected) connected.push(item);
        }

        // Sort: Connected first -> Paired second -> Discovered alphabetically
        parsed.sort(function(a, b) {
            if (a.connected !== b.connected) return a.connected ? -1 : 1;
            if (a.paired !== b.paired) return a.paired ? -1 : 1;
            return a.name.localeCompare(b.name);
        });

        devices = parsed;
        connectedDevices = connected;
    }
}