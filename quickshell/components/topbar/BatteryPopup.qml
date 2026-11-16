import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../.."
import "../../services"

PanelWindow {
  id: popup
  property var battery: null
  property var toast: null

  visible: battery !== null && battery.popupOpen
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
      BatteryController.refreshBattery();
      BatteryController.refreshProfiles();
    }
  }

  Connections {
    target: BatteryController
    function onIsChargingChanged() { popupBackground.requestPaint(); }
    function onProfileChanged(profileName, success) {
      if (success) {
        popup.toast?.showToast("POWER // " + profileName.toUpperCase() + " ACTIVE", false);
      } else {
        popup.toast?.showToast("POWER // PROFILE CHANGE FAILED", true);
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: if (popup.battery) popup.battery.popupOpen = false
  }

  Item {
    id: popupCard
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: Theme.barHeight
    width: 260
    height: 216
    z: 1

    MouseArea {
      anchors.fill: parent
      z: -1
      onClicked: mouse => mouse.accepted = true
    }

    Canvas {
      id: popupBackground
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
        ctx.strokeStyle = BatteryController.isCharging ? Theme.yellow : Theme.cyan;
        ctx.stroke();
      }
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 12
      spacing: 6

      ColumnLayout {
        Text {
          text: BatteryController.isCharging ? "BATTERY // CHARGING" : "BATTERY // ON POWER"
          color: BatteryController.isCharging ? Theme.yellow : Theme.cyan
          font.family: Theme.fontFamily
          font.bold: true
        }
        Text {
          text: BatteryController.level >= 0
              ? "CHARGE\t// " + BatteryController.level + "%"
              : "CHARGE\t|| UNKNOWN"
          color: Theme.fg
          font.family: Theme.fontFamily
          font.pixelSize: 11
        }
        Text {
          text: {
            if (BatteryController.remainingMinutes < 0) {
              return BatteryController.isCharging ? "TO_FULL\t// CALCULATING..." : "REMAINING\t// AC / IDLE";
            }
            return BatteryController.isCharging
                ? "TO_FULL\t// " + BatteryController.timeRemainingText
                : "REMAINING\t// " + BatteryController.timeRemainingText;
          }
          color: BatteryController.isCharging ? Theme.yellow : Theme.fg
          font.family: Theme.fontFamily
          font.pixelSize: 11
        }
        Text {
          text: BatteryController.capacityWh >= 0
              ? "CAPACITY\t// " + BatteryController.capacityWh.toFixed(1) + "Wh"
              : "CAPACITY // UNKNOWN"
          color: Theme.fg
          font.family: Theme.fontFamily
          font.pixelSize: 11
        }
        Text {
          text: BatteryController.health >= 0
              ? "HEALTH\t// " + BatteryController.health.toFixed(0) + "%"
              : "HEALTH // UNKNOWN"
          color: Theme.fg
          font.family: Theme.fontFamily
          font.pixelSize: 11
        }
        Text {
          text: BatteryController.powerDrawWatts !== -1
              ? "PWR_DRAW\t// " + (BatteryController.powerDrawWatts > 0 ? "+" : "") + BatteryController.powerDrawWatts.toFixed(2) + "W"
              : "PWR_DRAW // UNKNOWN"
          color: Theme.fg
          font.family: Theme.fontFamily
          font.pixelSize: 11
        }
        Text {
          text: BatteryController.status.toUpperCase()
          color: Theme.fgDim
          font.family: Theme.fontFamily
          font.pixelSize: 10
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Repeater {
          model: BatteryController.powerProfiles
          delegate: Item {
            required property string modelData
            required property int index

            property string profileName: modelData
            property bool selected: profileName === BatteryController.activeProfile
            property bool first: index === 0
            property bool last: index === popup.powerProfiles.length - 1

            Layout.fillWidth: true
            implicitHeight: 32

            onSelectedChanged: profileBackground.requestPaint()

            Canvas {
              id: profileBackground
              anchors.fill: parent
              onPaint: {
                var ctx = getContext("2d");
                var cut = Theme.cornerCutSizeSmall;
                ctx.clearRect(0, 0, width, height);
                ctx.beginPath();
                ctx.moveTo(0, 0);
                ctx.lineTo(last ? width - cut : width, 0);
                if (last) ctx.lineTo(width, cut);
                ctx.lineTo(width, height);
                ctx.lineTo(first ? cut : 0, height);
                if (first) ctx.lineTo(0, height - cut);
                ctx.closePath();
                ctx.fillStyle = Theme.surface;
                ctx.fill();
                ctx.lineWidth = 2;
                ctx.strokeStyle = selected ? Theme.magenta : Theme.surface;
                ctx.stroke();
              }
            }

            Text {
              anchors.centerIn: parent
              text: profileName.toUpperCase().replace("-", "_")
              color: selected ? Theme.magenta : Theme.fgDim
              font.family: Theme.fontFamily
              font.bold: true
              font.pixelSize: 10
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: BatteryController.selectProfile(profileName)
            }
          }
        }

        Text {
          visible: BatteryController.powerProfiles.length === 0
          text: "POWER PROFILES // UNAVAILABLE"
          color: Theme.fgDim
          font.family: Theme.fontFamily
          font.pixelSize: 10
        }
      }
    }
  }
}