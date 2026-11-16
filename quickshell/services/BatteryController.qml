pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    // --- Configuration ---
    property string device: "BAT0"

    // --- Public Reactive State ---
    property int level: -1
    property string status: "Unknown"
    readonly property string normalizedStatus: status.trim().toLowerCase()
    readonly property bool isCharging: normalizedStatus === "charging"
    readonly property bool isDischarging: normalizedStatus === "discharging"
    readonly property bool isPluggedIn: normalizedStatus === "charging"
        || normalizedStatus === "full"
        || normalizedStatus === "not charging"

    property real capacityWh: -1       // Full charge capacity in Wh
    property real health: -1           // Percentage (0-100), -1 if unknown
    property real powerDrawWatts: -1   // Signed Watts (+charging, -discharging), -1 if unknown

    property var powerProfiles: []
    property string activeProfile: ""
    property bool switchingProfile: profileSetProcess.running

    signal profileChanged(string profileName, bool success)

    // --- 1. Event-Driven AC / Battery State Monitor ---
    Process {
        id: monitorProcess
        command: ["upower", "--monitor"]
        running: true
        stdout: SplitParser {
            onRead: line => eventDebounce.restart()
        }
        onExited: monitorRestartTimer.start()
    }

    Timer {
        id: eventDebounce
        interval: 200
        repeat: false
        onTriggered: root.refreshBattery()
    }

    Timer {
        id: monitorRestartTimer
        interval: 2000
        repeat: false
        onTriggered: monitorProcess.running = true
    }

    // Light periodic refresh for gradual percentage & wattage drift
    Timer {
        id: pollTimer
        interval: 10000
        repeat: true
        running: true
        onTriggered: root.refreshBattery()
    }

    // --- 2. Sysfs Battery Reader (Supports both energy_* and charge_*) ---
    Process {
        id: batteryProcess
        command: [
            "sh", "-c",
            "base=/sys/class/power_supply/${1:-BAT0}; " +
            "[ -d \"$base\" ] || exit 1; " +
            "cap=$(cat \"$base/capacity\" 2>/dev/null || echo -1); " +
            "stat=$(cat \"$base/status\" 2>/dev/null || echo Unknown); " +
            "ef=$(cat \"$base/energy_full\" 2>/dev/null || cat \"$base/charge_full\" 2>/dev/null || echo -1); " +
            "efd=$(cat \"$base/energy_full_design\" 2>/dev/null || cat \"$base/charge_full_design\" 2>/dev/null || echo -1); " +
            "pn=$(cat \"$base/power_now\" 2>/dev/null || echo -1); " +
            "if [ \"$pn\" = \"-1\" ] && [ -r \"$base/current_now\" ] && [ -r \"$base/voltage_now\" ]; then " +
            "  cn=$(cat \"$base/current_now\"); vn=$(cat \"$base/voltage_now\"); " +
            "  pn=$(( (cn * vn) / 1000000 )); " +
            "fi; " +
            "printf '%s\\n%s\\n%s\\n%s\\n%s\\n' \"$cap\" \"$stat\" \"$ef\" \"$efd\" \"$pn\"",
            "battery", root.device
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split(/\r?\n/);
                if (lines.length < 5) return;

                var parsedLevel = Number.parseInt(lines[0], 10);
                var rawStatus = (lines[1] ?? "Unknown").trim();
                var parsedFull = Number.parseInt(lines[2], 10);
                var parsedDesign = Number.parseInt(lines[3], 10);
                var parsedPowerUw = Number.parseInt(lines[4], 10);

                root.level = Number.isFinite(parsedLevel) ? parsedLevel : -1;
                root.status = rawStatus;

                // Capacity in Wh (sysfs energy_full is in uWh)
                root.capacityWh = (Number.isFinite(parsedFull) && parsedFull > 0)
                    ? (parsedFull / 1000000.0)
                    : -1;

                // Health percentage (only valid when both full and design > 0)
                if (Number.isFinite(parsedFull) && parsedFull > 0
                        && Number.isFinite(parsedDesign) && parsedDesign > 0) {
                    var pct = (parsedFull / parsedDesign) * 100.0;
                    root.health = pct > 100 ? 100 : pct;
                } else {
                    root.health = -1;
                }

                // Power draw in Watts (sysfs power_now is in uW)
                if (Number.isFinite(parsedPowerUw) && parsedPowerUw >= 0) {
                    var watts = parsedPowerUw / 1000000.0;
                    var discharging = rawStatus.toLowerCase() === "discharging";
                    root.powerDrawWatts = discharging ? -watts : watts;
                } else {
                    root.powerDrawWatts = -1;
                }
            }
        }
    }

    // --- 3. Power Profiles ---
    Process {
        id: profileListProcess
        command: ["powerprofilesctl", "list"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var profiles = [];
                var selected = "";
                text.split(/\r?\n/).forEach(function(line) {
                    var match = line.match(/^(?:\s*\*\s+| {2})([a-z][a-z0-9_-]*)\s*:\s*$/i);
                    if (match) {
                        var name = match[1];
                        if (profiles.indexOf(name) === -1) {
                            profiles.push(name);
                        }
                        if (/^\s*\*/.test(line)) {
                            selected = name;
                        }
                    }
                });
                profiles.reverse();
                root.powerProfiles = profiles;
                root.activeProfile = selected || (profiles.length > 0 ? profiles[0] : "");
            }
        }
    }

    property string _pendingProfile: ""

    Process {
        id: profileSetProcess
        command: ["powerprofilesctl", "set", root._pendingProfile]
        onExited: function(exitCode) {
            var target = root._pendingProfile;
            root._pendingProfile = "";
            if (exitCode === 0) {
                root.activeProfile = target;
                root.refreshProfiles();
                root.profileChanged(target, true);
            } else {
                root.profileChanged(target, false);
            }
        }
    }

    // --- Public API ---
    function refreshBattery() {
        if (!batteryProcess.running) batteryProcess.running = true;
    }

    function refreshProfiles() {
        if (!profileListProcess.running) profileListProcess.running = true;
    }

    function selectProfile(profile) {
        if (!profile || profile === activeProfile || profileSetProcess.running) return;
        _pendingProfile = profile;
        profileSetProcess.running = true;
    }
}