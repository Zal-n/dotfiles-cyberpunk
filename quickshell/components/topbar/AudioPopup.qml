import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import ".."
import "../.."

PanelWindow {
    id: popup
    property var audio: null
    property var toast: null
    property real volume: audio?.volume ?? -1
    property bool muted: audio?.muted ?? false
    property bool adjusting: false
    property string pendingVolume: "0.00"
    readonly property string sink: audio?.sink ?? "@DEFAULT_AUDIO_SINK@"

    visible: audio !== null && audio.popupOpen
    WlrLayershell.layer: WlrLayer.Overlay
    anchors { top: true; left: true; right: true; bottom: true }
    implicitWidth: 0
    implicitHeight: 0
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    Process {
        id: volumeSetProcess
        command: ["wpctl", "set-volume", popup.sink, popup.pendingVolume]
    }

    Process {
        id: muteProcess
        command: ["wpctl", "set-mute", popup.sink, "toggle"]
    }

    MouseArea {
        anchors.fill: parent
        onClicked: popup.audio.popupOpen = false
    }

    Item {
        id: popupCard
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Theme.barHeight
        width: 280
        height: 150
        z: 1

        MouseArea { anchors.fill: parent; z: -1 }

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
                ctx.strokeStyle = Theme.magenta;
                ctx.stroke();
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "AUDIO // OUTPUT"
                    color: Theme.magenta
                    font.family: Theme.fontFamily
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: popup.muted ? "MUTED" : popup.volume >= 0 ? Math.round(popup.volume * 100) + "%" : "UNKNOWN"
                    color: popup.muted ? Theme.yellow : Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: popup.muted ? "󰖁" : "󰕾"
                    color: popup.muted ? Theme.magenta : Theme.cyan
                    font.family: Theme.fontFamily
                    font.pixelSize: 18
                }
                QuickSlider {
                    Layout.fillWidth: true
                    value: Math.max(0, popup.volume)
                    enabled: popup.volume >= 0
                    accentColor: Theme.magenta
                    onMoved: popup.setVolume(value)
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 30
                color: Theme.surface
                border.color: popup.muted ? Theme.yellow : Theme.magenta
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: popup.muted ? "UNMUTE OUTPUT" : "MUTE OUTPUT"
                    color: popup.muted ? Theme.yellow : Theme.magenta
                    font.family: Theme.fontFamily
                    font.bold: true
                    font.pixelSize: 10
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: popup.toggleMute()
                }
            }
        }
    }

    function setVolume(value) {
        var next = Math.max(0, Math.min(1, value));
        if (popup.audio) popup.audio.suppressNextToast = true;
        if (volumeSetProcess.running) return;
        popup.pendingVolume = next.toFixed(2);
        volumeSetProcess.running = true;
        popup.volume = next;
        if (popup.audio) popup.audio.volume = next;
        popup.toast?.showToast("AUDIO // " + Math.round(next * 100) + "%", false);
    }

    function toggleMute() {
        if (muteProcess.running) return;
        muteProcess.running = true;
        if (popup.audio) popup.audio.suppressNextToast = true;
        if (popup.audio) popup.audio.muted = !popup.audio.muted;
        popup.toast?.showToast(popup.muted ? "AUDIO // MUTED" : "AUDIO // UNMUTED", false);
    }
}
