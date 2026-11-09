import QtQuick
import Quickshell
import Quickshell.Wayland
import "../.."

PanelWindow {
    id: popup
    property var battery: null

    visible: battery !== null && battery.popupOpen
    WlrLayershell.layer: WlrLayer.Overlay
    anchors.top: true
    anchors.right: true
    margins.top: Theme.barHeight
    margins.right: 0
    implicitWidth: 260
    implicitHeight: 100
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

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
                ctx.strokeStyle = popup.battery?.isCharging ? Theme.yellow : Theme.cyan;
                ctx.stroke();
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 6

            Text {
                text: popup.battery?.isCharging ? "BATTERY // CHARGING" : "BATTERY // ON POWER"
                color: popup.battery?.isCharging ? Theme.yellow : Theme.cyan
                font.family: Theme.fontFamily
                font.bold: true
            }
            Text {
                text: popup.battery && popup.battery.capacity >= 0
                    ? "CHARGE // " + popup.battery.capacity + "%"
                    : "CHARGE // UNKNOWN"
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
            Text {
                text: popup.battery ? popup.battery.status.toUpperCase() : "UNKNOWN"
                color: Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: popup.battery.popupOpen = false
        }
    }
}
