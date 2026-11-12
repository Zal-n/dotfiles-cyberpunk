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
    anchors {
        top: position.indexOf("top-") === 0
        bottom: position.indexOf("bottom-") === 0
        left: position.endsWith("-left") || position.endsWith("-center")
        right: position.endsWith("-right") || position.endsWith("-center")
    }
    margins {
        top: 24
        bottom: 24
        left: position.endsWith("-center") && screen
            ? Math.max(0, (screen.width - toastWidth) / 2)
            : 24
        right: position.endsWith("-center") && screen
            ? Math.max(0, (screen.width - toastWidth) / 2)
            : 24
    }
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
            id: toastCanvas
            anchors.fill: parent
            Connections {
                target: toast
                function onMessageChanged() { toastCanvas.requestPaint(); }
                function onFailedChanged() { toastCanvas.requestPaint(); }
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
