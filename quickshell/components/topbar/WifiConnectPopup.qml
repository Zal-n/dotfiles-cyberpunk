import QtQuick
import Quickshell
import Quickshell.Wayland
import "../.."
import ".."
import "../../services"

PanelWindow {
    id: modal

    readonly property var network: WifiController.modalNetwork
    readonly property bool isSaved: network !== null && WifiController.isSaved(network.ssid)
    readonly property bool isEnterprise: network !== null
        && (network.security ?? "").indexOf("802.1X") !== -1
    readonly property bool isOpen: network !== null
        && (network.security ?? "") === ""

    property bool showCredentialOverride: false
    property bool passwordVisible: false

    readonly property bool showCredentialFields: network !== null
        && !network.unavailable
        && !isOpen
        && (!isSaved || showCredentialOverride)

    visible: WifiController.connectModalOpen && network !== null
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    color: "#88000000"
    exclusionMode: ExclusionMode.Ignore

    onVisibleChanged: {
        if (visible) {
            showCredentialOverride = false;
            passwordVisible = false;
            identityInput.text = "";
            passwordInput.text = "";
            if (showCredentialFields) {
                if (isEnterprise) identityInput.forceActiveFocus();
                else passwordInput.forceActiveFocus();
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: WifiController.closeConnectModal()
    }

    Item {
        id: card
        anchors.centerIn: parent
        width: 310
        height: contentCol.implicitHeight + 28
        z: 1

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        Canvas {
            id: cardBg
            width: card.width
            height: card.height
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
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
            id: contentCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 8

            // Header row
            Row {
                width: parent.width
                Text {
                    width: parent.width - 20
                    text: modal.isEnterprise
                        ? "802.1X // ENTERPRISE AUTH"
                        : "WIFI // AUTHENTICATION"
                    color: Theme.cyan
                    font.family: Theme.fontFamily
                    font.bold: true
                    font.pixelSize: 11
                }
                Text {
                    text: "✕"
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WifiController.closeConnectModal()
                    }
                }
            }

            // Network Summary
            Text {
                width: parent.width
                text: modal.network ? modal.network.ssid : ""
                color: Theme.fg
                font.family: Theme.fontFamily
                font.bold: true
                font.pixelSize: 13
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: {
                    if (!modal.network) return "";
                    if (modal.network.unavailable) return "STATUS // OUT OF RANGE";
                    var sec = modal.network.security || "OPEN";
                    var savedTag = modal.isSaved ? " // SAVED" : "";
                    return "SIGNAL // " + modal.network.signal + "%  •  " + sec + savedTag;
                }
                color: Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: 9
            }

            // Saved network credential override toggle
            Rectangle {
                visible: modal.isSaved && !modal.network.unavailable && !modal.isOpen && !modal.showCredentialOverride
                width: parent.width
                height: 24
                color: "transparent"
                border.color: Theme.fgDim
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "CHANGE CREDENTIALS"
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        modal.showCredentialOverride = true;
                        if (modal.isEnterprise) identityInput.forceActiveFocus();
                        else passwordInput.forceActiveFocus();
                    }
                }
            }

            // PEAP / 802.1X Identity Input
            Rectangle {
                visible: modal.showCredentialFields && modal.isEnterprise
                width: parent.width
                height: 30
                color: Theme.surface
                border.color: identityInput.activeFocus ? Theme.cyan : Theme.fgDim
                border.width: 1

                Text {
                    visible: identityInput.text.length === 0 && !identityInput.activeFocus
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: "IDENTITY (E.G. USER@DOMAIN)"
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                }

                TextInput {
                    id: identityInput
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    KeyNavigation.tab: passwordInput
                    Keys.onReturnPressed: passwordInput.forceActiveFocus()
                    Keys.onEscapePressed: WifiController.closeConnectModal()
                }
            }

            // Password Input with Show/Hide Toggle
            Rectangle {
                visible: modal.showCredentialFields
                width: parent.width
                height: 30
                color: Theme.surface
                border.color: passwordInput.activeFocus ? Theme.cyan : Theme.fgDim
                border.width: 1

                Text {
                    visible: passwordInput.text.length === 0 && !passwordInput.activeFocus
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: "PASSWORD"
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                }

                TextInput {
                    id: passwordInput
                    anchors.left: parent.left
                    anchors.right: toggleEye.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 8
                    anchors.rightMargin: 4
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.fg
                    echoMode: modal.passwordVisible ? TextInput.Normal : TextInput.Password
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    Keys.onReturnPressed: {
                        if (!WifiController.connecting) {
                            WifiController.connect(modal.network, passwordInput.text, identityInput.text);
                        }
                    }
                    Keys.onEscapePressed: WifiController.closeConnectModal()
                }

                Text {
                    id: toggleEye
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: modal.passwordVisible ? "󰈉" : "󰈈"
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modal.passwordVisible = !modal.passwordVisible
                    }
                }
            }

            // Connect Button
            Rectangle {
                visible: modal.network !== null && !modal.network.unavailable
                width: parent.width
                height: 28
                color: WifiController.connecting ? Theme.surfaceAccent : Theme.cyan
                Text {
                    anchors.centerIn: parent
                    text: WifiController.connecting ? "CONNECTING..." : "CONNECT"
                    color: Theme.bg
                    font.family: Theme.fontFamily
                    font.bold: true
                    font.pixelSize: 10
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: !WifiController.connecting
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WifiController.connect(modal.network, passwordInput.text, identityInput.text)
                }
            }

            // Forget Button
            Rectangle {
                visible: modal.isSaved
                width: parent.width
                height: 24
                color: Theme.surfaceAccent
                Text {
                    anchors.centerIn: parent
                    text: WifiController.forgetting ? "FORGETTING..." : "FORGET NETWORK"
                    color: Theme.magenta
                    font.family: Theme.fontFamily
                    font.bold: true
                    font.pixelSize: 9
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: !WifiController.forgetting && !WifiController.connecting
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WifiController.forget(modal.network)
                }
            }

            // Error / Status Feedback
            Text {
                visible: WifiController.statusMessage.length > 0
                width: parent.width
                text: WifiController.statusMessage
                color: WifiController.statusIsError ? Theme.magenta : Theme.cyan
                font.family: Theme.fontFamily
                font.pixelSize: 9
                wrapMode: Text.WordWrap
            }
        }
    }
}
