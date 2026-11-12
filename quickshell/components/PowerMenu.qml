import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import ".."

PanelWindow {
    id: powerMenu

    property var config: root.config.desktop?.powerMenu ?? ({})
    property var toast: null
    readonly property string position: config.position ?? "bottom-center"
    readonly property int holdTime: Math.max(100, Number(config.holdTime ?? 1500))
    readonly property var entries: config.entries ?? defaultEntries
    property var heldEntry: null
    property int holdElapsed: 0
    readonly property real holdProgress: Math.min(1, holdElapsed / holdTime)

    readonly property var defaultEntries: [
        { "id": "poweroff", "label": "POWER OFF", "key": "x", "hold": true },
        { "id": "restart", "label": "RESTART", "key": "r" },
        { "id": "lock", "label": "LOCK", "key": "l" },
        { "id": "logout", "label": "LOGOUT", "key": "o" },
        { "id": "exit-niri", "label": "EXIT NIRI", "key": "e" }
    ]

    visible: root.powerMenuOpen
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    implicitWidth: 0
    implicitHeight: 0
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    onVisibleChanged: {
        if (visible) {
            Qt.callLater(function() {
                if (powerMenu.visible) keyboardFocus.forceActiveFocus();
            });
        } else {
            cancelHold();
        }
    }

    Process {
        id: actionProcess
        onExited: function(exitCode) {
            if (exitCode !== 0 && powerMenu.toast) {
                powerMenu.toast.showToast("POWER // ACTION FAILED", true);
            }
        }
    }

    Timer {
        id: holdTimer
        interval: 50
        repeat: true
        onTriggered: {
            powerMenu.holdElapsed += interval;
            if (powerMenu.heldEntry && powerMenu.holdElapsed >= powerMenu.holdTime) {
                var entry = powerMenu.heldEntry;
                powerMenu.finishHold();
                powerMenu.triggerEntry(entry);
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: powerMenu.close()
    }

    Item {
        id: popupCard
        width: 360
        height: Math.max(86, entries.length * 44 + 24)
        z: 1
        anchors.top: position.indexOf("top-") === 0 ? parent.top : undefined
        anchors.bottom: position.indexOf("bottom-") === 0 ? parent.bottom : undefined
        anchors.left: position.endsWith("-left") ? parent.left : undefined
        anchors.right: position.endsWith("-right") ? parent.right : undefined
        anchors.horizontalCenter: position.endsWith("-center") ? parent.horizontalCenter : undefined
        anchors.verticalCenter: position === "center" ? parent.verticalCenter : undefined
        anchors.topMargin: 24
        anchors.bottomMargin: 24
        anchors.leftMargin: 24
        anchors.rightMargin: 24

        MouseArea {
            anchors.fill: parent
            z: -1
        }

        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d");
                var cut = Theme.cornerCutSize;
                ctx.clearRect(0, 0, width, height);
                ctx.beginPath();
                ctx.moveTo(0, 0);
                ctx.lineTo(width, 0);
                ctx.lineTo(width, height - cut);
                ctx.lineTo(width - cut, height);
                ctx.lineTo(0, height);
                ctx.closePath();
                ctx.fillStyle = Theme.bg;
                ctx.fill();
                ctx.lineWidth = 2;
                ctx.strokeStyle = Theme.magenta;
                ctx.stroke();
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 6

            Text {
                text: "POWER // MENU"
                color: Theme.yellow
                font.family: Theme.fontFamily
                font.bold: true
                font.pixelSize: 12
            }

            Repeater {
                model: powerMenu.entries
                delegate: Rectangle {
                    property var entry: modelData
                    Layout.fillWidth: true
                    implicitHeight: 32
                    color: entryMouse.containsMouse ? Theme.surfaceAccent : Theme.surface
                    border.color: entryMouse.containsMouse ? Theme.cyan : Theme.surfaceAccent
                    border.width: 1

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width
                            * (powerMenu.heldEntry
                               && powerMenu.heldEntry.id === entry.id
                               ? powerMenu.holdProgress
                               : 0)
                        color: Theme.magenta
                        opacity: 0.35
                        Behavior on width {
                            NumberAnimation {
                                duration: 50
                                easing.type: Easing.Linear
                            }
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            text: entry.label ?? entry.id ?? "ACTION"
                            color: entryMouse.containsMouse ? Theme.cyan : Theme.fg
                            font.family: Theme.fontFamily
                            font.bold: true
                            font.pixelSize: 11
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "HOLD " + String(entry.key ?? "").toUpperCase()
                            color: Theme.yellow
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }
                    }

                    MouseArea {
                        id: entryMouse
                        anchors.fill: parent
                        enabled: powerMenu.visible
                        hoverEnabled: true
                        preventStealing: true
                        onPressed: function(mouse) {
                            mouse.accepted = true;
                            powerMenu.startHold(entry);
                        }
                        onReleased: function(mouse) {
                            mouse.accepted = true;
                            if (powerMenu.heldEntry
                                    && powerMenu.heldEntry.id === entry.id) {
                                powerMenu.cancelHold();
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        id: keyboardFocus
        anchors.fill: parent
        focus: true
        activeFocusOnTab: true
        Keys.onPressed: function(event) {
            if (event.isAutoRepeat) {
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Escape) {
                powerMenu.close();
                event.accepted = true;
                return;
            }

            var entry = powerMenu.entryForKey(event);
            if (!entry) {
                return;
            }
            event.accepted = true;
            powerMenu.startHold(entry);
        }
        Keys.onReleased: function(event) {
            if (powerMenu.heldEntry && powerMenu.keyMatches(powerMenu.heldEntry.key, event)) {
                powerMenu.cancelHold();
                event.accepted = true;
            }
        }
    }

    function keyMatches(key, event) {
        var normalized = String(key ?? "").toLowerCase();
        if (normalized.length === 1) {
            return event.text.toLowerCase() === normalized;
        }
        if (normalized === "escape") return event.key === Qt.Key_Escape;
        if (normalized === "enter") return event.key === Qt.Key_Return || event.key === Qt.Key_Enter;
        if (normalized === "space") return event.key === Qt.Key_Space;
        return false;
    }

    function entryForKey(event) {
        for (var i = 0; i < entries.length; i++) {
            if (keyMatches(entries[i].key, event)) {
                return entries[i];
            }
        }
        return null;
    }

    function cancelHold() {
        holdTimer.stop();
        heldEntry = null;
        holdElapsed = 0;
    }

    function startHold(entry) {
        if (actionProcess.running || heldEntry) {
            return;
        }
        heldEntry = entry;
        holdElapsed = 0;
        holdTimer.restart();
    }

    function finishHold() {
        holdTimer.stop();
        holdElapsed = holdTime;
    }

    function commandFor(id) {
        switch (id) {
        case "poweroff":
            return ["systemctl", "poweroff"];
        case "restart":
            return ["systemctl", "reboot"];
        case "lock":
            return ["loginctl", "lock-session"];
        case "logout":
            return ["loginctl", "terminate-user", Quickshell.env("USER")];
        case "exit-niri":
            return ["niri", "msg", "action", "quit"];
        default:
            return [];
        }
    }

    function triggerEntry(entry) {
        var command = commandFor(entry.id);
        if (command.length === 0) {
            if (powerMenu.toast) {
                powerMenu.toast.showToast("POWER // UNKNOWN ACTION", true);
            }
            return;
        }
        if (actionProcess.running) {
            return;
        }
        actionProcess.command = command;
        actionProcess.running = true;
        powerMenu.close();
    }

    function open() {
        root.closeTransientWindows();
        root.powerMenuOpen = true;
    }

    function close() {
        cancelHold();
        root.powerMenuOpen = false;
    }
}
