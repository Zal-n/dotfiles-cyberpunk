import QtQuick
import Quickshell
import Quickshell.Io
import "../.."

Item {
    id: audio
    property var topbar
    property var moduleConfig: ({})
    property var toast: null
    readonly property var preset: topbar ? topbar.modulePreset(moduleConfig) : ({})
    property real volume: -1
    property bool muted: false
    property bool suppressNextToast: false
    property bool hasInitialState: false
    property bool popupOpen: false
    readonly property string popupKey: "audio"
    readonly property string sink: moduleConfig.sink ?? "@DEFAULT_AUDIO_SINK@"

    width: audioContent.implicitWidth
    height: audioContent.implicitHeight

    Process {
        id: volumeProcess
        command: ["wpctl", "get-volume", audio.sink]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var match = text.match(/Volume:\s+([0-9.]+)(?:\s+\[MUTED\])?/);
                if (!match) {
                    audio.volume = -1;
                    audio.muted = false;
                    return;
                }
                var nextVolume = Number.parseFloat(match[1]);
                var nextMuted = text.indexOf("[MUTED]") !== -1;
                var changed = audio.hasInitialState
                    && (Math.abs(audio.volume - nextVolume) > 0.001 || audio.muted !== nextMuted);
                audio.volume = nextVolume;
                audio.muted = nextMuted;
                if (changed) {
                    if (audio.suppressNextToast) {
                        audio.suppressNextToast = false;
                    } else {
                        audio.toast?.showToast(
                            nextMuted ? "AUDIO // MUTED" : "AUDIO // " + Math.round(nextVolume * 100) + "%",
                            false
                        );
                    }
                }
                audio.hasInitialState = true;
                refreshTimer.restart();
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: audio.preset.refreshInterval ?? 2000
        repeat: true
        running: true
        onTriggered: if (!volumeProcess.running) volumeProcess.running = true
    }

    Row {
        id: audioContent
        spacing: 4

        Text {
            visible: (audio.preset.style ?? "icon") === "icon"
            text: audio.muted
                ? (audio.preset.mutedIcon ?? "󰖁")
                : audio.volume < 0
                ? (audio.preset.unknownIcon ?? "󰕾")
                : audio.volume === 0
                ? (audio.preset.mutedIcon ?? "󰖁")
                : audio.volume < 0.34
                ? (audio.preset.lowIcon ?? "󰕿")
                : audio.volume < 0.67
                ? (audio.preset.mediumIcon ?? "󰖀")
                : (audio.preset.highIcon ?? "󰕾")
            color: audio.muted ? Theme.yellow : Theme.magenta
            font.family: Theme.fontFamily
            font.pixelSize: audio.preset.fontSize ?? 16
        }

        Item {
            visible: audio.preset.style === "bars"
            width: (audio.preset.barCount ?? 5) * (audio.preset.barWidth ?? 3)
                + ((audio.preset.barCount ?? 5) - 1) * (audio.preset.barSpacing ?? 2)
            height: audio.preset.barHeight ?? 18

            Row {
                anchors.bottom: parent.bottom
                spacing: audio.preset.barSpacing ?? 2

                Repeater {
                    model: audio.preset.barCount ?? 5
                    delegate: Rectangle {
                        property int barIndex: index
                        width: audio.preset.barWidth ?? 3
                        height: Math.max(3, (audio.preset.barHeight ?? 18) * (barIndex + 1) / (audio.preset.barCount ?? 5))
                        anchors.bottom: parent.bottom
                        color: audio.muted
                            ? Theme.yellow
                            : audio.volume >= 0 && barIndex < Math.ceil(audio.volume * (audio.preset.barCount ?? 5))
                            ? Theme.magenta
                            : Theme.surface
                        border.color: audio.muted ? Theme.yellow : Theme.magenta
                        border.width: 1
                    }
                }
            }
        }

        Text {
            visible: audio.preset.showPercentage === true
            text: audio.volume >= 0 ? Math.round(audio.volume * 100) + "%" : "??%"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: audio.preset.fontSize ?? 13
        }
    }

    MouseArea {
        anchors.fill: audioContent
        cursorShape: Qt.PointingHandCursor
        onClicked: audio.topbar.togglePopup(audio)
    }
}
