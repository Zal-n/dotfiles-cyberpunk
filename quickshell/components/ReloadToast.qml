import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."

PanelWindow {
    id: toast
    property string message: ""
    property bool failed: false
    property string position: "bottom-center"
    property int duration: 2200
    readonly property int toastWidth: 300

    WlrLayershell.layer: WlrLayer.Overlay
    x: position.endsWith("-left")
        ? 24
        : position.endsWith("-right")
        ? (screen ? screen.width - width - 24 : 0)
        : (screen ? (screen.width - width) / 2 : 0)
    y: position.indexOf("top-") === 0
        ? 24
        : (screen ? screen.height - height - 24 : 0)
    implicitWidth: toastWidth
    implicitHeight: 42
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: message.length > 0

    function showToast(nextMessage, isFailure, nextPosition, nextDuration) {
        message = nextMessage;
        failed = isFailure === true;
        if (nextPosition) position = nextPosition;
        duration = nextDuration ?? 2200;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: toast.duration
        onTriggered: toast.message = ""
    }

    Item {
        width: toast.toastWidth
        height: 42

        Canvas {
            anchors.fill: parent
            Connections {
                target: toast
                function onMessageChanged() { parent.requestPaint(); }
                function onFailedChanged() { parent.requestPaint(); }
            }
            onPaint: {
                var ctx = getContext("2d");
                var cut = 12;
                ctx.clearRect(0, 0, width, height);
                ctx.beginPath();
                ctx.moveTo(0, 0);
                ctx.lineTo(width, 0);
                ctx.lineTo(width, height - cut);
                ctx.lineTo(width - cut, height);
                ctx.lineTo(0, height);
                ctx.closePath();
                ctx.fillStyle = toast.failed ? Theme.magenta : Theme.bg;
                ctx.fill();
                ctx.lineWidth = 2;
                ctx.strokeStyle = toast.failed ? Theme.yellow : Theme.cyan;
                ctx.stroke();
            }
        }

        RowLayout {
            id: toastContent
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Text {
                text: toast.failed ? "!" : ">"
                color: toast.failed ? Theme.yellow : Theme.cyan
                font.family: Theme.fontFamily
                font.bold: true
                font.pixelSize: 16
            }

            Text {
                text: toast.message
                color: toast.failed ? Theme.bg : Theme.fg
                font.family: Theme.fontFamily
                font.bold: true
                font.pixelSize: 11
            }
        }
    }
}
