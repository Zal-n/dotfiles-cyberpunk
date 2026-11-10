import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import ".."
import "../.."

PanelWindow {
    id: cc
    signal closeRequested()
    signal openSettingsRequested()
    property string pendingBrightness: "0%"
    property string pendingVolume: "0.00"

    WlrLayershell.layer: WlrLayer.Overlay

    anchors { top: true; right: true }
    margins.top: Theme.barHeight
    margins.right: 0
    visible: false
    implicitWidth: 340
    implicitHeight: 420
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    Process {
        id: brightnessProcess
        command: ["brightnessctl", "set", cc.pendingBrightness]
    }

    Process {
        id: volumeProcess
        command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", cc.pendingVolume]
    }

    Process { id: rebootProcess; command: ["systemctl", "reboot"] }
    Process { id: poweroffProcess; command: ["systemctl", "poweroff"] }


    MouseArea {
      id: mouseArea
      anchors.fill: parent
      hoverEnabled: true
    }
    Item {
        anchors.fill: parent

        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d");
                var cut = Theme.cornerCutSize; // Lecsapás mérete (bal alsó sarok)
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
                ctx.lineWidth = 2;
                ctx.strokeStyle = Theme.cyan;
                ctx.stroke();
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16

            RowLayout {
                Text {
                    text: "SYSTEM CONTROL // HARDWARE"
                    color: Theme.yellow
                    font.family: Theme.fontFamily
                    font.bold: true
                    font.pixelSize: 13
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "[X]"
                    color: Theme.magenta
                    font.family: Theme.fontFamily
                    font.bold: true
                    MouseArea {
                        anchors.fill: parent
                        onClicked: cc.closeRequested()
                    }
                }
            }

            GridLayout {
                columns: 2
                columnSpacing: 10
                rowSpacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 60
                    color: Theme.surface
                    border.color: Theme.cyan
                    border.width: 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        Text { text: "󰤨 WI-FI"; color: Theme.cyan; font.family: Theme.fontFamily; font.bold: true }
                        Text { text: "CONNECTED"; color: Theme.fgDim; font.family: Theme.fontFamily; font.pixelSize: 10 }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 60
                    color: Theme.surface
                    border.color: Theme.magenta
                    border.width: 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        Text { text: "󰂯 BLUETOOTH"; color: Theme.magenta; font.family: Theme.fontFamily; font.bold: true }
                        Text { text: "ACTIVE"; color: Theme.fgDim; font.family: Theme.fontFamily; font.pixelSize: 10 }
                    }
                }
            }

            ColumnLayout {
                spacing: 12
                Layout.fillWidth: true

                Text { text: "DISPLAY BRIGHTNESS (OLED 165Hz)"; color: Theme.fg; font.family: Theme.fontFamily; font.pixelSize: 11 }
                QuickSlider {
                    accentColor: Theme.cyan
                    onMoved: cc.setBrightness(value)
                }

                Text { text: "MASTER AUDIO OUTPUT"; color: Theme.fg; font.family: Theme.fontFamily; font.pixelSize: 11 }
                QuickSlider {
                    accentColor: Theme.magenta
                    onMoved: cc.setVolume(value)
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                spacing: 8
                Rectangle {
                  Canvas {
                        anchors.fill: parent
                        onPaint: {
                        var ctx = getContext("2d");
                        var cut = Theme.cornerCutSizeSmall;
                        ctx.clearRect(0, 0, width, height);
                        ctx.beginPath();

                        ctx.moveTo(0, 0);
                        ctx.lineTo(width, 0);
                        ctx.lineTo(width, height);
                        ctx.lineTo(cut, height);
                        ctx.lineTo(0, height-cut);

                        ctx.closePath();

                        ctx.fillStyle = Theme.surface;
                        ctx.fill();
                        ctx.lineWidth = 2;
                        ctx.strokeStyle = Theme.magenta;
                        ctx.stroke();
                      }
                    }
                    Layout.fillWidth: true
                    implicitHeight: 32
                    color: Theme.surface
                    //border.color: Theme.magenta
                    border.width: 1
                    Text { anchors.centerIn: parent; text: "REBOOT"; color: Theme.magenta; font.family: Theme.fontFamily; font.bold: true }
                    MouseArea { anchors.fill: parent; onClicked: if (!rebootProcess.running) rebootProcess.running = true }

                    
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 32
                    color: Theme.magenta
                    Text { anchors.centerIn: parent; text: "SHUTDOWN"; color: Theme.bg; font.family: Theme.fontFamily; font.bold: true }
                    MouseArea { anchors.fill: parent; onClicked: if (!poweroffProcess.running) poweroffProcess.running = true }
                }

            }
        }
    }

    function setBrightness(value) {
        if (brightnessProcess.running) return;
        cc.pendingBrightness = Math.round(value * 100) + "%";
        brightnessProcess.running = true;
    }

    function setVolume(value) {
        if (volumeProcess.running) return;
        cc.pendingVolume = value.toFixed(2);
        volumeProcess.running = true;
    }
}
