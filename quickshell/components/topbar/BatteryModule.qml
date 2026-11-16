import QtQuick
import Quickshell
import "../.."
import "../../services"

Item {
    id: battery
    property var topbar
    property var moduleConfig: ({})
    readonly property var preset: topbar ? topbar.modulePreset(moduleConfig) : ({})

    property bool popupOpen: false
    readonly property string popupKey: "battery"
    readonly property int popupHeight: 100

    width: batteryContent.implicitWidth
    height: batteryContent.implicitHeight

    Component.onCompleted: {
        if (moduleConfig.device) {
            BatteryController.device = moduleConfig.device;
            BatteryController.refreshBattery();
        }
    }

    Row {
        id: batteryContent
        spacing: 4

        Text {
            readonly property var iconSet: battery.preset.icons ?? ({})
            readonly property string iconKey: {
                if (BatteryController.level < 0) return "unknown";
                if (BatteryController.isCharging) return "charging";
                if (BatteryController.level >= 80) return "full";
                if (BatteryController.level >= 40) return "high";
                if (BatteryController.level >= 20) return "medium";
                if (BatteryController.level >= 10) return "low";
                return "critical";
            }
            visible: battery.preset.style === "icon-label" && battery.preset.showIcon !== false
            text: iconSet[iconKey] ?? iconSet.unknown ?? "󰁹"
            color: BatteryController.isCharging
                ? battery.topbar.presetColor(battery.preset.chargingColor)
                : battery.topbar.presetColor(battery.preset.normalColor)
            font.family: Theme.fontFamily
            font.pixelSize: battery.preset.fontSize ?? 13
        }

        Text {
            visible: BatteryController.level >= 0
            text: {
                var format = battery.preset.format ?? "{percentage}%";
                return format.replace("{percentage}", BatteryController.level);
            }
            color: BatteryController.isCharging
                ? battery.topbar.presetColor(battery.preset.chargingColor)
                : battery.topbar.presetColor(battery.preset.normalColor)
            font.family: Theme.fontFamily
            font.pixelSize: battery.preset.fontSize ?? 13
        }
    }

    MouseArea {
        anchors.fill: batteryContent
        cursorShape: Qt.PointingHandCursor
        onClicked: battery.topbar.togglePopup(battery)
    }
}