import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import ".."

PanelWindow {
    id: bar
    signal controlCenterToggled()
    signal settingsToggled()

    readonly property var cfg: root.config.topbar ?? ({})
    readonly property var presets: root.topbarPresets

    WlrLayershell.layer: WlrLayer.Top

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight
    color: Theme.bg

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        implicitHeight: 2
        color: Theme.cyan
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16

        RowLayout {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12
            Repeater {
                model: bar.cfg.left ?? []
                delegate: Loader {
                    property var moduleConfig: modelData
                    sourceComponent: bar.moduleComponent(modelData.id)
                    onLoaded: item.moduleConfig = moduleConfig
                }
            }
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: 12
            Repeater {
                model: bar.cfg.center ?? []
                delegate: Loader {
                    property var moduleConfig: modelData
                    sourceComponent: bar.moduleComponent(modelData.id)
                    onLoaded: item.moduleConfig = moduleConfig
                }
            }
        }

        RowLayout {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Repeater {
                model: bar.cfg.right ?? []
                delegate: Loader {
                    property var moduleConfig: modelData
                    sourceComponent: bar.moduleComponent(modelData.id)
                    onLoaded: item.moduleConfig = moduleConfig
                }
            }
        }
    }

    function modulePreset(module) {
        return bar.presets[module.id]?.[module.preset ?? "default"] ?? ({});
    }

    function moduleComponent(moduleId) {
        switch (moduleId) {
        case "logo":
            return logoModule;
        case "clock":
            return clockModule;
        case "settings":
            return settingsModule;
        case "controlCenter":
            return controlCenterModule;
        case "separator":
            return separatorModule;
        case "workspaceDisplay":
            return workspaceDisplayModule;
        case "battery":
            return batteryModule;
        case "wifi":
            return wifiModule;
        default:
            return null;
        }
    }

    Component {
        id: logoModule
        Text {
            property var moduleConfig: ({})
            readonly property var preset: bar.modulePreset(moduleConfig)
            visible: moduleConfig.visible !== false
            text: preset.text ?? ""
            color: Theme.cyan
            font.family: Theme.fontFamily
            font.bold: true
            font.pixelSize: preset.fontSize ?? 13
        }
    }

    Component {
        id: clockModule
        Text {
            property var moduleConfig: ({})
            readonly property var preset: bar.modulePreset(moduleConfig)
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
    }

    Component {
        id: separatorModule
        Text {
            property var moduleConfig: ({})
            readonly property var preset: bar.modulePreset(moduleConfig)
            text: preset.text ?? "//"
            color: Theme.fgDim
            font.family: Theme.fontFamily
            font.bold: true
        }
    }

    Component {
        id: workspaceDisplayModule
        Row {
            id: workspaceDisplay
            property var moduleConfig: ({})
            readonly property var preset: bar.modulePreset(moduleConfig)
            property var workspaces: []
            spacing: preset.spacing ?? 6

            function workspaceIsFocused(workspace) {
                return workspace.is_focused === true || workspace.is_focused === "true";
            }

            Process {
                id: workspaceProcess
                command: ["niri", "msg", "-j", "workspaces"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        try {
                            var parsed = JSON.parse(text);
                            workspaceDisplay.workspaces = Array.isArray(parsed) ? parsed : [];
                        } catch (e) {
                            workspaceDisplay.workspaces = [];
                        }
                    }

                }
                onRunningChanged: {
                    if (!running) {
                        refreshTimer.restart();
                    }
                }
            }

            Timer {
                id: refreshTimer
                interval: 1000
                repeat: true
                running: true
                onTriggered: workspaceProcess.running = true
            }

            Process {
                id: focusWorkspaceProcess
                command: []
            }

            function focusWorkspace(workspace) {
                var target = workspace.idx ?? workspace.id;
                if (target === undefined || target === null || focusWorkspaceProcess.running) {
                    return;
                }
                focusWorkspaceProcess.command = ["niri", "msg", "action", "focus-workspace", String(target)];
                focusWorkspaceProcess.running = true;
            }

            Repeater {
                model: workspaceDisplay.workspaces
                delegate: Loader {
                    property var workspace: modelData
                    property var workspacePreset: bar.modulePreset(workspaceDisplay.moduleConfig)
                    sourceComponent: {
                        switch (workspacePreset.style ?? "dots") {
                        case "numbers":
                            return numberWorkspace;
                        case "rectangles":
                            return rectangleWorkspace;
                        default:
                            return dotWorkspace;
                        }
                    }
                    onLoaded: {
                        item.workspace = workspace;
                        item.preset = workspacePreset;
                    }
                }
            }

            Component {
                id: dotWorkspace
                Rectangle {
                    property var workspace: ({})
                    property var preset: ({})
                    width: preset.size ?? 7
                    height: width
                    radius: width / 2
                    color: workspaceDisplay.workspaceIsFocused(workspace)
                        ? bar.presetColor(preset.activeColor)
                        : bar.presetColor(preset.inactiveColor)

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: workspaceDisplay.focusWorkspace(parent.workspace)
                    }
                }
            }

            Component {
                id: rectangleWorkspace
                Rectangle {
                    property var workspace: ({})
                    property var preset: ({})
                    width: preset.width ?? 16
                    height: preset.height ?? 5
                    color: workspaceDisplay.workspaceIsFocused(workspace)
                        ? bar.presetColor(preset.activeColor)
                        : bar.presetColor(preset.inactiveColor)

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: workspaceDisplay.focusWorkspace(parent.workspace)
                    }
                }
            }

            Component {
                id: numberWorkspace
                Text {
                    property var workspace: ({})
                    property var preset: ({})
                    text: workspace.idx ?? workspace.id ?? "?"
                    color: workspaceDisplay.workspaceIsFocused(workspace)
                        ? bar.presetColor(preset.activeColor)
                        : bar.presetColor(preset.inactiveColor)
                    font.family: Theme.fontFamily
                    font.pixelSize: preset.fontSize ?? 11

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: workspaceDisplay.focusWorkspace(parent.workspace)
                    }
                }
            }
        }
    }

    Component {
        id: batteryModule
        Row {
            id: battery
            property var moduleConfig: ({})
            readonly property var preset: bar.modulePreset(moduleConfig)
            property int capacity: -1
            property string status: "Unknown"
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
                    ? bar.presetColor(battery.preset.chargingColor)
                    : bar.presetColor(battery.preset.normalColor)
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
                    ? bar.presetColor(battery.preset.chargingColor)
                    : bar.presetColor(battery.preset.normalColor)
                font.family: Theme.fontFamily
                font.pixelSize: battery.preset.fontSize ?? 13
            }
        }
    }

    Component {
        id: wifiModule
        Item {
            id: wifi
            property var moduleConfig: ({})
            readonly property var preset: bar.modulePreset(moduleConfig)
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
                    ? bar.presetColor(wifi.preset.connectedColor)
                    : bar.presetColor(wifi.preset.disconnectedColor)
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
    }

    function presetColor(name) {
        switch (name) {
        case "cyan":
            return Theme.cyan;
        case "magenta":
            return Theme.magenta;
        case "yellow":
            return Theme.yellow;
        case "fg":
            return Theme.fg;
        default:
            return Theme.fgDim;
        }
    }

    Component {
        id: settingsModule
        Rectangle {
            property var moduleConfig: ({})
            readonly property var preset: bar.modulePreset(moduleConfig)
            width: 30
            height: 26
            color: Theme.surface
            border.color: Theme.cyan
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: parent.preset.text ?? "⚙"
                color: Theme.cyan
                font.family: Theme.fontFamily
                font.pixelSize: 20
            }
            MouseArea {
                anchors.fill: parent
                onClicked: bar.settingsToggled()
            }
        }
    }

    Component {
        id: controlCenterModule
        Rectangle {
            property var moduleConfig: ({})
            readonly property var preset: bar.modulePreset(moduleConfig)
            width: 100
            height: 26
            color: Theme.surface
            border.color: Theme.magenta
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: parent.preset.text ?? "CTRL"
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.bold: true
            }
            MouseArea {
                anchors.fill: parent
                onClicked: bar.controlCenterToggled()
            }
        }
    }
}
