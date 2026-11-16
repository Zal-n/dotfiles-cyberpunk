import QtQuick
import QtQuick.Layouts
import Quickshell
import "../.."
import "../../services"

Item {
    property real gridWidth: 4
    property real gridHeight: 2
    readonly property bool compact: gridWidth <= 1 && gridHeight <= 1

    ColumnLayout {
        visible: compact
        anchors.fill: parent
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: BluetoothController.connectedCount > 0 ? "󰂱" : (BluetoothController.powered ? "󰂯" : "󰂲")
            color: BluetoothController.powered ? Theme.cyan : Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: 24
        }
    }

    ColumnLayout {
        visible: !compact
        anchors.fill: parent
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "BLUETOOTH"
                color: BluetoothController.powered ? Theme.cyan : Theme.fgDim
                font.family: Theme.fontFamily
                font.bold: true
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                visible: BluetoothController.powered
                width: 22
                height: 18
                color: listBtnHover.containsMouse ? Theme.surfaceAccent : "transparent"
                border.color: Theme.fgDim
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "☰"
                    color: Theme.cyan
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
                MouseArea {
                    id: listBtnHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.controlCenterOpen = false;
                        BluetoothController.popupOpen = true;
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: {
                if (!BluetoothController.available) return "NO ADAPTER";
                if (!BluetoothController.powered) return "POWER // OFF";
                if (BluetoothController.connectedCount === 1) {
                    return BluetoothController.primaryDeviceName.toUpperCase();
                }
                if (BluetoothController.connectedCount > 1) {
                    return BluetoothController.connectedCount + " DEVICES ACTIVE";
                }
                return "POWER // ON";
            }
            color: BluetoothController.connectedCount > 0 ? Theme.cyan : Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 11
            elide: Text.ElideRight
        }

        Text {
            text: BluetoothController.powered
                ? "L-CLICK TOGGLE // R-CLICK LIST"
                : "CLICK TO ENABLE"
            color: Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: 9
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                root.controlCenterOpen = false;
                BluetoothController.popupOpen = true;
            } else {
                BluetoothController.togglePower();
            }
        }
    }
}