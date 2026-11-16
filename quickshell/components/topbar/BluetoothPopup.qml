import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../.."
import "../../services"

PanelWindow {
    id: popup

    function glyphForIcon(iconName) {
        if (!iconName) return "󰂯";
        if (iconName.indexOf("headset") !== -1 || iconName.indexOf("headphone") !== -1) return "󰋋";
        if (iconName.indexOf("audio") !== -1) return "󰓃";
        if (iconName.indexOf("mouse") !== -1) return "󰍽";
        if (iconName.indexOf("keyboard") !== -1) return "󰌌";
        if (iconName.indexOf("phone") !== -1) return "󰏲";
        if (iconName.indexOf("gaming") !== -1 || iconName.indexOf("joypad") !== -1) return "󰊴";
        return "󰂯";
    }

    visible: BluetoothController.popupOpen
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

    onVisibleChanged: {
        if (visible) {
            BluetoothController.clearStatus();
            BluetoothController.refreshAll();
            if (BluetoothController.powered) BluetoothController.startScan();
        } else {
            BluetoothController.stopScan();
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: BluetoothController.popupOpen = false
    }

    Item {
        id: popupCard
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Theme.barHeight
        width: 280
        height: 480
        z: 1

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
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

        Flickable {
            id: popupFlickable
            anchors.fill: parent
            anchors.margins: 12
            contentWidth: width
            contentHeight: popupContent.implicitHeight
            clip: true
            z: 1
            ScrollBar.vertical: ScrollBar {}

            Column {
                id: popupContent
                width: popupFlickable.width
                spacing: 6

                Text {
                    text: BluetoothController.powered ? "BLUETOOTH // ACTIVE" : "BLUETOOTH // OFFLINE"
                    color: BluetoothController.powered ? Theme.cyan : Theme.magenta
                    font.family: Theme.fontFamily
                    font.bold: true
                }

                Text {
                    width: popupContent.width
                    text: BluetoothController.connectedCount > 0
                        ? BluetoothController.primaryDeviceName + (BluetoothController.connectedCount > 1 ? " (+" + (BluetoothController.connectedCount - 1) + ")" : "")
                        : "NO CONNECTED DEVICES"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }

                Rectangle {
                    width: popupContent.width
                    height: 26
                    color: BluetoothController.powered ? Theme.surfaceAccent : Theme.magenta
                    Text {
                        anchors.centerIn: parent
                        text: BluetoothController.powered ? "BLUETOOTH RADIO // ON" : "BLUETOOTH RADIO // OFF"
                        color: BluetoothController.powered ? Theme.cyan : Theme.bg
                        font.family: Theme.fontFamily
                        font.bold: true
                        font.pixelSize: 10
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: BluetoothController.togglePower()
                    }
                }

                Rectangle {
                    visible: BluetoothController.powered
                    width: popupContent.width
                    height: 24
                    color: Theme.surfaceAccent
                    Text {
                        anchors.centerIn: parent
                        text: BluetoothController.discovering ? "SCANNING (15S)..." : "SCAN FOR DEVICES"
                        color: Theme.cyan
                        font.family: Theme.fontFamily
                        font.bold: true
                        font.pixelSize: 9
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: !BluetoothController.discovering
                        cursorShape: Qt.PointingHandCursor
                        onClicked: BluetoothController.startScan()
                    }
                }

                Text {
                    visible: BluetoothController.powered
                    text: "DEVICES"
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }

                Repeater {
                    model: BluetoothController.powered ? BluetoothController.devices : []
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool isBusy: BluetoothController.busyMac === modelData.mac
                        width: popupContent.width
                        height: 32
                        color: rowHover.containsMouse ? Theme.surfaceAccent : "transparent"

                        MouseArea {
                            id: rowHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: BluetoothController.toggleDevice(modelData)
                        }

                        Text {
                            id: devGlyph
                            anchors.left: parent.left
                            anchors.leftMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            text: popup.glyphForIcon(modelData.icon)
                            color: modelData.connected ? Theme.cyan : Theme.fgDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                        }

                        Column {
                            anchors.left: devGlyph.right
                            anchors.leftMargin: 8
                            anchors.right: forgetBtn.visible ? forgetBtn.left : parent.right
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                width: parent.width
                                text: modelData.name
                                color: modelData.connected ? Theme.cyan : Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: modelData.connected
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: {
                                    if (isBusy) return "WORKING...";
                                    var state = modelData.connected
                                        ? "CONNECTED"
                                        : (modelData.paired ? "PAIRED" : "AVAILABLE");
                                    var bat = modelData.battery >= 0 ? "  •  BAT " + modelData.battery + "%" : "";
                                    return state + bat;
                                }
                                color: Theme.fgDim
                                font.family: Theme.fontFamily
                                font.pixelSize: 8
                            }
                        }

                        // Remove / Unpair button for paired devices
                        Rectangle {
                            id: forgetBtn
                            visible: modelData.paired && !isBusy
                            anchors.right: parent.right
                            anchors.rightMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            width: 20
                            height: 20
                            color: forgetHover.containsMouse ? Theme.surface : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                color: Theme.magenta
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                            }

                            MouseArea {
                                id: forgetHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: BluetoothController.removeDevice(modelData)
                            }
                        }
                    }
                }

                Text {
                    visible: BluetoothController.statusMessage.length > 0
                    width: popupContent.width
                    text: BluetoothController.statusMessage
                    color: BluetoothController.statusIsError ? Theme.magenta : Theme.cyan
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}