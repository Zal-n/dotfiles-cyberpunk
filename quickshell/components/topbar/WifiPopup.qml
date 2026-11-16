import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../.."
import "../../services"

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

    onVisibleChanged: {
        if (visible) {
            WifiController.refreshAll();
            WifiController.scan();
        }
    }

    Connections {
        target: WifiController
        function onConnectionSucceeded() {
            if (popup.wifi) popup.wifi.popupOpen = false;
        }
    }

    Timer {
        interval: 10000
        repeat: true
        running: popup.visible && WifiController.radioEnabled && !WifiController.connectModalOpen
        onTriggered: WifiController.scan()
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: if (popup.wifi) popup.wifi.popupOpen = false
    }

    Item {
        id: popupCard
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Theme.barHeight
        width: 260
        height: 520
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
                    text: {
                        if (!WifiController.connected) return "NETWORK // OFFLINE";
                        return WifiController.connectionType === "ethernet"
                            ? "ETHERNET // CONNECTED"
                            : "WIFI // CONNECTED";
                    }
                    color: WifiController.connected ? Theme.cyan : Theme.magenta
                    font.family: Theme.fontFamily
                    font.bold: true
                }

                Text {
                    text: {
                        if (!WifiController.connected) return "NO ACTIVE NETWORK";
                        return WifiController.connectionType === "ethernet"
                            ? WifiController.activeName + " // WIRED"
                            : WifiController.activeName + " // " + WifiController.signal + "%";
                    }
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    width: popupContent.width
                }

                Rectangle {
                    width: popupContent.width
                    height: 26
                    color: WifiController.radioEnabled ? Theme.surfaceAccent : Theme.magenta
                    Text {
                        anchors.centerIn: parent
                        text: WifiController.radioEnabled ? "WIFI RADIO // ON" : "WIFI RADIO // OFF"
                        color: WifiController.radioEnabled ? Theme.cyan : Theme.bg
                        font.family: Theme.fontFamily
                        font.bold: true
                        font.pixelSize: 10
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WifiController.toggleRadio()
                    }
                }

                Text {
                    text: WifiController.radioEnabled ? "AVAILABLE NETWORKS" : "ENABLE WIFI TO SCAN"
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }

                Rectangle {
                    visible: WifiController.radioEnabled
                    width: popupContent.width
                    height: 24
                    color: Theme.surfaceAccent
                    Text {
                        anchors.centerIn: parent
                        text: WifiController.scanning ? "SCANNING..." : "REFRESH NETWORKS"
                        color: Theme.cyan
                        font.family: Theme.fontFamily
                        font.bold: true
                        font.pixelSize: 9
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: !WifiController.scanning
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WifiController.scan()
                    }
                }

                Repeater {
                    model: WifiController.radioEnabled
                        ? WifiController.displayNetworks.slice(0, 16) : []
                    delegate: Rectangle {
                        required property var modelData
                        width: popupContent.width
                        height: 26
                        color: hoverArea.containsMouse ? Theme.surfaceAccent : "transparent"

                        MouseArea {
                            id: hoverArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WifiController.selectNetwork(modelData)
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 6
                            anchors.right: manageBtn.visible ? manageBtn.left : parent.right
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            text: (modelData.connected ? "● " : "○ ")
                                + modelData.ssid
                                + (modelData.unavailable ? "  [OUT OF RANGE]" : "  " + modelData.signal + "%")
                                + (modelData.saved && !modelData.unavailable ? "  [SAVED]" : "")
                            color: modelData.connected
                                ? Theme.cyan
                                : (modelData.unavailable ? Theme.fgDim : Theme.fg)
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }

                        // Manage button on saved networks (to Forget or Change Password)
                        Rectangle {
                            id: manageBtn
                            visible: modelData.saved && !modelData.unavailable
                            anchors.right: parent.right
                            anchors.rightMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            width: 20
                            height: 20
                            color: manageHover.containsMouse ? Theme.surface : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "⚙"
                                color: Theme.fgDim
                                font.family: Theme.fontFamily
                                font.pixelSize: 24
                            }

                            MouseArea {
                                id: manageHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: WifiController.openConnectModal(modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}