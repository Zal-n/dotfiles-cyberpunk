pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    // --- Public Reactive State ---
    property bool connected: false
    property string connectionType: "none"   // "wifi" | "ethernet" | "none"
    property string activeName: ""           // SSID or Ethernet profile name
    property int signal: 0
    property bool radioEnabled: false

    property var networks: []
    property var savedNetworks: []
    property var displayNetworks: []         // Pre-sorted merged list for UI binding

    property bool scanning: scanProcess.running
    property bool connecting: connectProcess.running
    property bool forgetting: forgetProcess.running
    property string statusMessage: ""
    property bool statusIsError: false

    // --- Internal Action State ---
    property string _targetSsid: ""
    property string _targetPassword: ""
    property string _targetIdentity: ""
    property string _targetConnName: ""
    property bool _isEnterprise: false

    signal connectionSucceeded()

    // --- 1. Event-Driven Monitor ---
    Process {
        id: monitorProcess
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser {
            onRead: line => eventDebounce.restart()
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

    // Light signal poll only while actively connected to Wi-Fi
    Timer {
        id: signalPollTimer
        interval: 15000
        repeat: true
        running: root.connectionType === "wifi" && root.radioEnabled
        onTriggered: {
            if (!wifiSignalProcess.running) wifiSignalProcess.running = true;
        }
    }

    // --- 2. Status & Device Queries ---
    Process {
        id: deviceStatusProcess
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split(/\r?\n/);
                var ethConn = "";
                var wifiConn = "";

                for (var i = 0; i < lines.length; i++) {
                    if (!lines[i]) continue;
                    var fields = root._parseEscapedFields(lines[i]);
                    var type = fields[1] ?? "";
                    var state = fields[2] ?? "";
                    var conn = fields[3] ?? "";

                    if (state === "connected") {
                        if (type === "ethernet" && !ethConn) ethConn = conn;
                        if (type === "wifi" && !wifiConn) wifiConn = conn;
                    }
                }

                if (ethConn) {
                    root.connected = true;
                    root.connectionType = "ethernet";
                    root.activeName = ethConn;
                    root.signal = 100;
                } else if (wifiConn) {
                    root.connected = true;
                    root.connectionType = "wifi";
                    root.activeName = wifiConn;
                    if (!wifiSignalProcess.running) wifiSignalProcess.running = true;
                } else {
                    root.connected = false;
                    root.connectionType = "none";
                    root.activeName = "";
                    root.signal = 0;
                }
            }
        }
    }

    Process {
        id: wifiSignalProcess
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL", "device", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split(/\r?\n/);
                for (var i = 0; i < lines.length; i++) {
                    if (lines[i].startsWith("*:")) {
                        var fields = root._parseEscapedFields(lines[i]);
                        root.signal = Number.parseInt(fields[1] ?? "0", 10) || 0;
                        return;
                    }
                }
            }
        }
    }

    Process {
        id: radioProcess
        command: ["nmcli", "radio", "wifi"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var enabled = text.trim() === "enabled";
                var turnedOn = !root.radioEnabled && enabled;
                root.radioEnabled = enabled;
                if (!enabled) {
                    root.networks = [];
                    root._rebuildDisplayNetworks();
                } else if (turnedOn) {
                    root.scan();
                }
            }
        }
    }

    Process {
        id: scanProcess
        command: [
            "nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY",
            "device", "wifi", "list", "--rescan", "yes"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                root.networks = root._parseNetworks(text);
                root._rebuildDisplayNetworks();
            }
        }
    }

    Process {
        id: savedProcess
        command: ["nmcli", "-t", "-f", "NAME,TYPE,802-11-wireless.ssid", "connection", "show"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.savedNetworks = root._parseSavedNetworks(text);
                root._rebuildDisplayNetworks();
            }
        }
    }

    // --- 3. User Actions (Decoupled from Popup Lifecycle) ---
    Process {
        id: toggleRadioProcess
        command: ["nmcli", "radio", "wifi", root.radioEnabled ? "off" : "on"]
        onExited: {
            radioProcess.running = true;
            deviceStatusProcess.running = true;
        }
    }

Process {
        id: connectProcess
        command: {
            // 1. Enterprise / PEAP (802.1X) with Identity + Password
            if (root._isEnterprise && root._targetIdentity.length > 0) {
                return [
                    "nmcli", "connection", "add",
                    "type", "wifi",
                    "con-name", root._targetSsid,
                    "ifname", "*",
                    "ssid", root._targetSsid,
                    "wifi-sec.key-mgmt", "wpa-eap",
                    "802-1x.eap", "peap",
                    "802-1x.phase2-auth", "mschapv2",
                    "802-1x.identity", root._targetIdentity,
                    "802-1x.password", root._targetPassword
                ];
            }
            // 2. WPA-PSK with new password
            if (root._targetPassword.length > 0) {
                return ["nmcli", "device", "wifi", "connect", root._targetSsid, "password", root._targetPassword];
            }
            // 3. Existing saved profile
            if (root._targetConnName.length > 0) {
                return ["nmcli", "connection", "up", "id", root._targetConnName];
            }
            // 4. Open network
            return ["nmcli", "device", "wifi", "connect", root._targetSsid];
        }
        stderr: StdioCollector { id: connectStderr }
        onExited: function(exitCode) {
            // If we just created a new 802.1X profile, bring it up immediately
            if (exitCode === 0 && root._isEnterprise && root._targetIdentity.length > 0) {
                root._isEnterprise = false;
                root._targetIdentity = "";
                root._targetPassword = "";
                root._targetConnName = root._targetSsid;
                connectProcess.running = true;
                return;
            }

            root._targetPassword = "";
            root._targetIdentity = "";
            root._isEnterprise = false;

            if (exitCode === 0) {
                root._setStatus("CONNECTED // " + root._targetSsid, false);
                root.connectModalOpen = false;
                root.refreshAll();
                root.connectionSucceeded();
            } else {
                var err = connectStderr.text.trim().replace(/^Error:\s*/i, "");
                root._setStatus(err ? err.toUpperCase() : "CONNECTION FAILED", true);
            }
        }
    }

    Process {
        id: forgetProcess
        command: ["nmcli", "connection", "delete", "id", root._targetConnName]
        stderr: StdioCollector { id: forgetStderr }
        onExited: function(exitCode) {
            if (exitCode === 0) {
                root._setStatus("FORGOTTEN // " + root._targetSsid, false);
                root.refreshAll();
                root.scan();
            } else {
                var err = forgetStderr.text.trim().replace(/^Error:\s*/i, "");
                root._setStatus(err ? err.toUpperCase() : "FORGET FAILED", true);
            }
        }
    }

    // --- Public API for UI Components ---

    function openConnectModal(network) {
        if (!network) return;
        modalNetwork = network;
        clearStatus();
        connectModalOpen = true;
    }

    function closeConnectModal() {
        connectModalOpen = false;
        modalNetwork = null;
        clearStatus();
    }

    function refreshAll() {
        if (!deviceStatusProcess.running) deviceStatusProcess.running = true;
        if (!radioProcess.running) radioProcess.running = true;
        if (!savedProcess.running) savedProcess.running = true;
    }

    function scan() {
        if (!radioEnabled || scanProcess.running) return;
        scanProcess.running = true;
    }

    function toggleRadio() {
        if (!toggleRadioProcess.running) toggleRadioProcess.running = true;
    }

    function isSaved(ssid) {
        return savedNetworks.some(function(c) { return c.ssid === ssid; });
    }

    function connectionNameFor(ssid) {
        var match = savedNetworks.find(function(c) { return c.ssid === ssid; });
        return match ? match.name : "";
    }

    function connect(network, password, identity) {
        if (!network || network.unavailable || connectProcess.running) return;
        _targetSsid = network.ssid;
        _targetPassword = password ?? "";
        _targetIdentity = identity ?? "";
        _targetConnName = connectionNameFor(network.ssid);
        _isEnterprise = (network.security ?? "").indexOf("802.1X") !== -1 || _targetIdentity.length > 0;
        _setStatus("CONNECTING // " + network.ssid, false);
        connectProcess.running = true;
    }

    function forget(network) {
        if (!network || forgetProcess.running || connectProcess.running) return;
        var connName = connectionNameFor(network.ssid);
        if (!connName) return;
        _targetSsid = network.ssid;
        _targetConnName = connName;
        forgetProcess.running = true;
    }

    function clearStatus() {
        statusMessage = "";
        statusIsError = false;
    }

    // --- Internal Helpers ---
    function _setStatus(msg, isError) {
        statusMessage = msg;
        statusIsError = isError;
    }

    function _parseEscapedFields(line) {
        var fields = [];
        var field = "";
        var escaped = false;
        for (var j = 0; j < line.length; j++) {
            var ch = line[j];
            if (escaped) {
                field += ch;
                escaped = false;
            } else if (ch === "\\") {
                escaped = true;
            } else if (ch === ":") {
                fields.push(field);
                field = "";
            } else {
                field += ch;
            }
        }
        fields.push(field);
        return fields;
    }

    function _parseNetworks(output) {
        var result = [];
        var seen = ({});
        var lines = output.trim().split(/\r?\n/);
        for (var i = 0; i < lines.length; i++) {
            if (!lines[i]) continue;
            var fields = _parseEscapedFields(lines[i]);
            var ssid = fields[1] ?? "";
            var sig = Number.parseInt(fields[2] ?? "0", 10) || 0;
            if (!ssid || sig <= 0 || seen[ssid]) continue;
            seen[ssid] = true;
            result.push({
                "ssid": ssid,
                "signal": sig,
                "security": fields[3] ?? "",
                "connected": fields[0] === "*",
                "saved": isSaved(ssid),
                "unavailable": false
            });
        }
        return result;
    }

    function _parseSavedNetworks(output) {
        var result = [];
        var lines = output.trim().split(/\r?\n/);
        for (var i = 0; i < lines.length; i++) {
            if (!lines[i]) continue;
            var fields = _parseEscapedFields(lines[i]);
            if (fields[1] !== "802-11-wireless") continue;
            result.push({
                "name": fields[0] ?? "",
                "ssid": fields[2] || fields[0] || ""
            });
        }
        return result;
    }

    function _rebuildDisplayNetworks() {
        var merged = [];
        var visible = ({});

        for (var i = 0; i < networks.length; i++) {
            var net = networks[i];
            visible[net.ssid] = true;
            merged.push({
                "ssid": net.ssid,
                "signal": net.signal,
                "security": net.security,
                "connected": net.connected,
                "saved": isSaved(net.ssid),
                "unavailable": false
            });
        }

        for (var j = 0; j < savedNetworks.length; j++) {
            var conn = savedNetworks[j];
            if (!conn.ssid || visible[conn.ssid]) continue;
            merged.push({
                "ssid": conn.ssid,
                "signal": 0,
                "security": "saved",
                "connected": false,
                "saved": true,
                "unavailable": true
            });
        }

        merged.sort(function(a, b) {
            if (a.connected !== b.connected) return a.connected ? -1 : 1;
            if (a.unavailable !== b.unavailable) return a.unavailable ? 1 : -1;
            return b.signal - a.signal;
        });

        displayNetworks = merged;
    }
}