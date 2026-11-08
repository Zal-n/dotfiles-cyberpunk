import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".."

PanelWindow {
    id: cc
    signal closeRequested()
    signal openSettingsRequested()

    WlrLayershell.layer: WlrLayer.Overlay

    anchors { top: true; right: true }
    margins.top: 44
    margins.right: 16

    implicitWidth: 340
    implicitHeight: 420
    color: "transparent"

    // Lecsapott sarkú Cyberpunk háttér (bal alsó sarok lecsapva)
    Item {
        anchors.fill: parent

        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d");
                var cut = 25; // Lecsapás mérete (bal alsó sarok)
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
                    onValueChanged: { Quickshell.exec(["brightnessctl", "set", Math.round(value * 100) + "%"]); }
                }

                Text { text: "MASTER AUDIO OUTPUT"; color: Theme.fg; font.family: Theme.fontFamily; font.pixelSize: 11 }
                QuickSlider {
                    accentColor: Theme.magenta
                    onValueChanged: { Quickshell.exec(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", value.toFixed(2)]); }
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
                        var cut = 15;
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
                    MouseArea { anchors.fill: parent; onClicked: Quickshell.exec(["systemctl", "reboot"]) }

                    
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 32
                    color: Theme.magenta
                    Text { anchors.centerIn: parent; text: "SHUTDOWN"; color: Theme.bg; font.family: Theme.fontFamily; font.bold: true }
                    MouseArea { anchors.fill: parent; onClicked: Quickshell.exec(["systemctl", "poweroff"]) }
                }
            }
        }
    }
}