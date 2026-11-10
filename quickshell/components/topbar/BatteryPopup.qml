import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../.."

PanelWindow {
  id: popup
  property var battery: null
  property int activeMode: 0

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

  MouseArea {
    anchors.fill: parent
    onClicked: popup.battery.popupOpen = false
  }

  Item {
    id: popupCard
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: Theme.barHeight
    width: 260
    height: 200
    z: 1

    MouseArea {
      anchors.fill: parent
      z: -1
    }

    Canvas {
      anchors.fill: parent
      id: popupBackground
      Connections {
        target: popup
        function onActiveModeChanged() { popupBackground.requestPaint(); }
      }
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
        ctx.strokeStyle = popup.battery?.isCharging ? Theme.yellow : Theme.cyan;
        ctx.stroke();
      }
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 12
      spacing: 6
      ColumnLayout {
        Text {
          text: popup.battery?.isCharging ? "BATTERY // CHARGING" : "BATTERY // ON POWER"
          color: popup.battery?.isCharging ? Theme.yellow : Theme.cyan
          font.family: Theme.fontFamily
          font.bold: true
        }
        Text {
          text: popup.battery && popup.battery.level >= 0
              ? "CHARGE\t// " + popup.battery.level + "%"
              : "CHARGE\t|| UNKNOWN"
          color: Theme.fg
          font.family: Theme.fontFamily
          font.pixelSize: 11
        }
        Text {
          text: popup.battery && popup.battery.capacity >= 0
              ? "CAPACITY\t// " + popup.battery.capacity/1000000 + "Wh"
              : "CAPACITY // UNKNOWN"
          color: Theme.fg
          font.family: Theme.fontFamily
          font.pixelSize: 11
        }
        Text {
          text: popup.battery && popup.battery.health >= 0
              ? "HEALTH\t// " + popup.battery.health + "%"
              : "HEALTH // UNKNOWN"
          color: Theme.fg
          font.family: Theme.fontFamily
          font.pixelSize: 11
        }
        Text {
          text: popup.battery && popup.battery.powerDraw >= 0
              ? "PWR_DRAW\t// " + popup.battery.powerDraw/10 + "W"
              : "PWR_DRAW // UNKNOWN"
          color: Theme.fg
          font.family: Theme.fontFamily
          font.pixelSize: 11
        }
        Text {
          text: popup.battery ? popup.battery.status.toUpperCase() : "UNKNOWN"
          color: Theme.fgDim
          font.family: Theme.fontFamily
          font.pixelSize: 10
        }
      }
      RowLayout {
        Layout.fillWidth: true 
        spacing: 6

        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 32
          color: Theme.surface
          border.width: 1

          Canvas {
            id: powerSaverBackground
            anchors.fill: parent
            Connections {
              target: popup
              function onActiveModeChanged() { powerSaverBackground.requestPaint(); }
            }
            onPaint: {
              var ctx = getContext("2d");
              var cut = Theme.cornerCutSizeSmall;
              ctx.clearRect(0, 0, width, height);
              ctx.beginPath();
              ctx.moveTo(0, 0);
              ctx.lineTo(width, 0);
              ctx.lineTo(width, height);
              ctx.lineTo(cut, height);
              ctx.lineTo(0, height - cut);
              ctx.closePath();

              ctx.fillStyle = Theme.surface;
              ctx.fill();
              ctx.lineWidth = 2;
              ctx.strokeStyle = popup.activeMode == 0 ? Theme.magenta : Theme.surface;
              ctx.stroke();
            }
          }

          Text {
            anchors.centerIn: parent
            text: "PWR_SVR"
            color: Theme.magenta
            font.family: Theme.fontFamily
            font.bold: true
          }

          MouseArea {
            anchors.fill: parent
            onClicked: {
              popup.activeMode = 0
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 32
          color: Theme.surface
          border.width: 0.5
          border.color: popup.activeMode == 1 ? Theme.magenta : Theme.surface

          Text {
            anchors.centerIn: parent
            text: "BALANCED"
            color: Theme.magenta
            font.family: Theme.fontFamily
            font.bold: true
          }
          MouseArea {
            anchors.fill: parent
            onClicked: {
              popup.activeMode = 1
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 32
          color: Theme.surface
          border.width: 1

          Canvas {
            id: performanceBackground
            anchors.fill: parent
            Connections {
              target: popup
              function onActiveModeChanged() { performanceBackground.requestPaint(); }
            }
            onPaint: {
              var ctx = getContext("2d");
              var cut = Theme.cornerCutSizeSmall;
              ctx.clearRect(0, 0, width, height);
              ctx.beginPath();
              ctx.moveTo(0, 0);
              ctx.lineTo(width-cut, 0);
              ctx.lineTo(width, cut);
              ctx.lineTo(width, height);
              ctx.lineTo(0, height);
              ctx.lineTo(0, 0);
              ctx.closePath();

              ctx.fillStyle = Theme.surface;
              ctx.fill();
              ctx.lineWidth = 2;
              ctx.strokeStyle = popup.activeMode == 2 ? Theme.magenta : Theme.surface;
              ctx.stroke();
            }
          }

          Text {
            anchors.centerIn: parent
            text: "PERF"
            color: Theme.magenta
            font.family: Theme.fontFamily
            font.bold: true
          }

          MouseArea {
            anchors.fill: parent
            onClicked: {
              popup.activeMode = 2;
            }
          }
        } 
      }
    }
  }
}
