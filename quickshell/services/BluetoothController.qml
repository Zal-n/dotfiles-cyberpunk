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

    property var devices: []
    property var connectedDevices: []
    readonly property int connectedCount: connectedDevices.length
    readonly property string primaryDeviceName: connectedDevices.length > 0
        ? connectedDevices[0].name
        : ""

    property string busyMac: ""
    property string statusMessage: ""
    property bool statusIsError: false

    // --- 1. Event-Driven BlueZ D-Bus Monitor (No PTY required) ---
    Process {
        id: monitorProcess
        command: [
            "dbus-monitor", "--system",
            "type='signal',sender='org.bluez'"
        ]
        running: true
        stdout: SplitParser {
            onRead: line => {
                if (line.indexOf("org.bluez.Adapter1") !== -1
                        || line.indexOf("org.bluez.Device1") !== -1
                        || line.indexOf("org.bluez.Battery1") !== -1
                        || line.indexOf("InterfacesAdded") !== -1
                        || line.indexOf("InterfacesRemoved") !== -1) {
                    eventDebounce.restart();
                }
            }
        }
        onExited: monitorRestartTimer.start()
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
                var clean = text.replace(/\x1b\[[0-9;]*[a-zA-Z]/g, "");
                if (!clean || clean.indexOf("No default controller available") !== -1) {
                    root.available = false;
                    root.powered = false;
                    root.discovering = false;
                    root.devices = [];
                    root.connectedDevices = [];
                    return;
                }
                root.available = true;
                root.powered = /Powered:\s+yes/i.test(clean);
                root.discovering = /Discovering:\s+yes/i.test(clean);

                if (root.powered) {
                    if (!deviceListProcess.running) deviceListProcess.running = true;
                } else {
                    root.devices = [];
                    root.connectedDevices = [];
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0) {
                    console.log("BluetoothController show stderr:", text.trim());
                }
            }
        }
    }

    Process {
        id: deviceListProcess
        command: [
            "sh", "-c",
            "bluetoothctl devices | sed -E 's/\\x1b\\[[0-9;]*[a-zA-Z]//g' | awk '/^Device / { print $2 }' | while read -r mac; do " +
            "  printf '===DEVICE===%s\\n' \"$mac\"; " +
            "  bluetoothctl info \"$mac\" | sed -E 's/\\x1b\\[[0-9;]*[a-zA-Z]//g'; " +
            "done"
        ]
        stdout: StdioCollector {
            onStreamFinished: root._parseDevicesBlock(text)
        }
    }

    // --- 3. User Actions ---
    Process {
        id: powerProcess
        onExited: function(exitCode) {
            if (exitCode === 0) {
                root.refreshAll();
            } else {
                root._setStatus("POWER TOGGLE FAILED (RFKILL?)", true);
            }
        }
    }

    Process {
        id: scanProcess
        command: ["bluetoothctl", "--timeout", "15", "scan", "on"]
        onRunningChanged: {
            if (running) {
                root.discovering = true;
                scanTimeoutTimer.restart();
            } else {
                root.discovering = false;
                root.refreshAll();
            }
        }
    }

    Process {
        id: deviceActionProcess
        stdout: StdioCollector { id: actionStdout }
        stderr: StdioCollector { id: actionStderr }
        onExited: function(exitCode) {
            root.busyMac = "";
            if (exitCode === 0) {
                root._setStatus("DEVICE UPDATED", false);
                root.refreshAll();
            } else {
                var raw = (actionStderr.text || actionStdout.text || "")
                    .replace(/\x1b\[[0-9;]*[a-zA-Z]/g, "").trim();
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
        var nextState = !powered;
        // Optimistic UI update + explicit command assignment
        powered = nextState;
        powerProcess.command = ["bluetoothctl", "power", nextState ? "on" : "off"];
        powerProcess.running = true;
    }

    function startScan() {
        if (!powered || scanProcess.running) return;
        scanProcess.running = true;
    }

    function stopScan() {
        if (scanProcess.running) {
            scanProcess.running = false;
        }
        discovering = false;
    }

    function toggleDevice(device) {
        if (!device || busyMac.length > 0 || deviceActionProcess.running) return;
        clearStatus();
        busyMac = device.mac;

        if (device.connected) {
            deviceActionProcess.command = ["bluetoothctl", "disconnect", device.mac];
        } else if (device.paired) {
            deviceActionProcess.command = ["bluetoothctl", "connect", device.mac];
        } else {
            deviceActionProcess.command = [
                "sh", "-c",
                "bluetoothctl pair \"$1\" && bluetoothctl trust \"$1\" && bluetoothctl connect \"$1\"",
                "bt-pair", device.mac
            ];
        }
        deviceActionProcess.running = true;
    }

    function removeDevice(device) {
        if (!device || busyMac.length > 0 || deviceActionProcess.running) return;
        clearStatus();
        busyMac = device.mac;
        deviceActionProcess.command = ["bluetoothctl", "remove", device.mac];
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
                    var batMatch = line.match(/\((\d+)\)/);
                    if (batMatch) battery = Number.parseInt(batMatch[1], 10);
                }
            }

            var displayName = alias || name || mac;
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

        parsed.sort(function(a, b) {
            if (a.connected !== b.connected) return a.connected ? -1 : 1;
            if (a.paired !== b.paired) return a.paired ? -1 : 1;
            return a.name.localeCompare(b.name);
        });

        devices = parsed;
        connectedDevices = connected;
    }
}