import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../.."
import "../../services"

Item {
    id: wifi
    property var topbar
    property var moduleConfig: ({})
    readonly property var preset: topbar ? topbar.modulePreset(moduleConfig) : ({})

    property bool popupOpen: false
    readonly property string popupKey: "wifi"
    readonly property int popupHeight: 100

    width: wifiIcon.width
    height: wifiIcon.height

    Text 
    {
        id: wifiIcon
        text:
        {
            if(!WifiController.connected)
            {
                return wifi.preset.icons?.disconnected ?? "󰤭";
            }
            if(WifiController.connectionType === "ethernet")
            {
                return wifi.preset.icons?.ethernet ?? "󰤨";
            }
            return wifi.preset.icons?.connected ?? "󰤨";
        }
        color: WifiController.connected
            ? wifi.topbar.presetColor(wifi.preset.connectedColor)
            : wifi.topbar.presetColor(wifi.preset.disconnectedColor)
        font.family: Theme.fontFamily
        font.pixelSize: wifi.preset.fontSize ?? 16

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: wifi.topbar.togglePopup(wifi)
        }

    }
}
