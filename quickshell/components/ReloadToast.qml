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
    readonly property int toastWidth: 300

    WlrLayershell.layer: WlrLayer.Overlay
    anchors { top: true; left: true; right: true; bottom: true }
    implicitWidth: 0
    implicitHeight: 0
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: message.length > 0

    function showToast(nextMessage, isFailure, nextPosition) {
        message = nextMessage;
        failed = isFailure === true;
        if (nextPosition) position = nextPosition;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: 2200
        onTriggered: toast.message = ""
    }

    Item {
        x: toast.position === "top-left" || toast.position === "bottom-left"
            ? 24
            : toast.position === "top-right" || toast.position === "bottom-right"
            ? parent.width - width - 24
            : (parent.width - width) / 2
        y: toast.position === "top-left" || toast.position === "top-center" || toast.position === "top-right"
            ? 24
            : parent.height - height - 24
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
