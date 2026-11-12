import QtQuick
import Quickshell
import Quickshell.Wayland
import "../.."

PanelWindow {
    id: popup
    property var wifi: null

    visible: wifi !== null && wifi.popupOpen
    WlrLayershell.layer: WlrLayer.Overlay
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    implicitWidth: 0
    implicitHeight: 0
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    MouseArea {
        anchors.fill: parent
        onClicked: popup.wifi.popupOpen = false
    }

    Item {
        id: popupCard
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Theme.barHeight
        width: 260
        height: 100
        z: 1

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
                text: popup.wifi?.connected ? "WIFI // CONNECTED" : "WIFI // OFFLINE"
                color: popup.wifi?.connected ? Theme.cyan : Theme.magenta
                font.family: Theme.fontFamily
                font.bold: true
            }
            Text {
                text: popup.wifi && popup.wifi.connected
                    ? popup.wifi.ssid + " // " + popup.wifi.signal + "%"
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
    }
}
