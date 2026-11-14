import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../.."

PanelWindow {
    id: popup
    property var wifi: null
    property var selectedNetwork: null
    property string passwordText: ""
    property string statusText: ""

    function selectedConnectionName() {
        if (!selectedNetwork || !wifi) return "";
        var connection = wifi.savedNetworks.find(function(item) {
            return item.ssid === selectedNetwork.ssid;
        });
        return connection?.name ?? selectedNetwork.ssid;
    }

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
        if (visible && wifi) {
            selectedNetwork = null;
            passwordText = "";
            statusText = "";
            passwordInput.text = "";
            wifi.scanNetworks();
            wifi.refreshSavedNetworks();
        }
    }

    Timer {
        interval: 10000
        repeat: true
        running: popup.visible && popup.wifi?.radioEnabled === true
        onTriggered: popup.wifi.scanNetworks()
    }

    Process {
        id: connectProcess
        command: popup.selectedNetwork && popup.passwordText.length > 0
            ? ["nmcli", "device", "wifi", "connect", popup.selectedNetwork.ssid,
                "password", popup.passwordText]
            : popup.selectedNetwork && popup.wifi?.isSaved(popup.selectedNetwork.ssid)
                ? ["nmcli", "connection", "up", "id", popup.selectedConnectionName()]
            : ["nmcli", "device", "wifi", "connect", popup.selectedNetwork?.ssid ?? ""]
        onExited: function(exitCode) {
            if (exitCode === 0) {
                popup.statusText = "CONNECTED // " + popup.selectedNetwork.ssid;
                popup.wifi.popupOpen = false;
                popup.wifi.refreshStatus();
                popup.wifi.refreshSavedNetworks();
            } else {
                popup.statusText = "CONNECTION FAILED";
            }
        }
    }

    Process {
        id: forgetProcess
        command: ["nmcli", "connection", "delete", "id", popup.selectedConnectionName()]
        onExited: function(exitCode) {
            if (exitCode === 0) {
                popup.statusText = "FORGOTTEN // " + popup.selectedNetwork.ssid;
                popup.selectedNetwork = null;
                popup.wifi.refreshSavedNetworks();
                popup.wifi.scanNetworks();
            } else {
                popup.statusText = "FORGET FAILED";
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: popup.wifi.popupOpen = false
    }

    Item {
        id: popupCard
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Theme.barHeight
        width: 260
        height: 560
        z: 1

        MouseArea {
            anchors.fill: parent
            onClicked: mouse.accepted = true
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

            Rectangle {
                width: popupContent.width
                height: 26
                color: popup.wifi?.radioEnabled ? Theme.surfaceAccent : Theme.magenta
                Text {
                    anchors.centerIn: parent
                    text: popup.wifi?.radioEnabled ? "WIFI RADIO // ON" : "WIFI RADIO // OFF"
                    color: popup.wifi?.radioEnabled ? Theme.cyan : Theme.bg
                    font.family: Theme.fontFamily
                    font.bold: true
                    font.pixelSize: 10
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: if (popup.wifi) popup.wifi.toggleRadio()
                }
            }

            Text {
                text: popup.wifi?.radioEnabled ? "AVAILABLE NETWORKS" : "ENABLE WIFI TO SCAN"
                color: Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }

            Rectangle {
                visible: popup.wifi?.radioEnabled === true
                width: popupContent.width
                height: 24
                color: Theme.surfaceAccent
                Text {
                    anchors.centerIn: parent
                    text: "REFRESH NETWORKS"
                    color: Theme.cyan
                    font.family: Theme.fontFamily
                    font.bold: true
                    font.pixelSize: 9
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: popup.wifi.scanNetworks()
                }
            }

            Repeater {
                model: popup.wifi?.radioEnabled
                    ? popup.wifi.displayNetworks().slice(0, 16) : []
                delegate: Rectangle {
                    required property var modelData
                    width: popupContent.width
                    height: 26
                    color: popup.selectedNetwork?.ssid === modelData.ssid
                        ? Theme.surfaceAccent : "transparent"
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        text: (modelData.connected ? "● " : "○ ")
                            + modelData.ssid + "  " + modelData.signal + "%"
                            + (popup.wifi.isSaved(modelData.ssid) ? "  [SAVED]" : "")
                            + (modelData.unavailable ? "  [OUT OF RANGE]" : "")
                        color: modelData.connected ? Theme.cyan : Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        width: parent.width - 12
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            popup.selectedNetwork = modelData;
                            popup.passwordText = "";
                            popup.statusText = "";
                            passwordInput.text = "";
                        }
                    }
                }
            }

            Rectangle {
                visible: popup.selectedNetwork !== null
                    && popup.selectedNetwork.security !== ""
                width: popupContent.width
                height: 30
                color: Theme.surface
                border.color: Theme.cyan
                border.width: 1
                Text {
                    visible: passwordInput.text.length === 0 && !passwordInput.activeFocus
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: "NETWORK PASSWORD"
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                }
                TextInput {
                    id: passwordInput
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    color: Theme.fg
                    echoMode: TextInput.Password
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    onTextChanged: popup.passwordText = text
                }
            }

            Rectangle {
                visible: popup.selectedNetwork !== null
                width: popupContent.width
                height: 26
                color: connectProcess.running ? Theme.surfaceAccent : Theme.cyan
                Text {
                    anchors.centerIn: parent
                    text: connectProcess.running ? "CONNECTING..." : "CONNECT"
                    color: Theme.bg
                    font.family: Theme.fontFamily
                    font.bold: true
                    font.pixelSize: 10
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: !connectProcess.running
                    onClicked: {
                        popup.statusText = "CONNECTING // " + popup.selectedNetwork.ssid;
                        connectProcess.running = true;
                    }
                }
            }

            Rectangle {
                visible: popup.selectedNetwork !== null
                    && popup.wifi.isSaved(popup.selectedNetwork.ssid)
                width: popupContent.width
                height: 24
                color: Theme.surfaceAccent
                Text {
                    anchors.centerIn: parent
                    text: forgetProcess.running ? "FORGETTING..." : "FORGET NETWORK"
                    color: Theme.magenta
                    font.family: Theme.fontFamily
                    font.bold: true
                    font.pixelSize: 9
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: !forgetProcess.running && !connectProcess.running
                    onClicked: forgetProcess.running = true
                }
            }

            Text {
                visible: popup.statusText.length > 0
                text: popup.statusText
                color: Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
        }
        }
    }
}
