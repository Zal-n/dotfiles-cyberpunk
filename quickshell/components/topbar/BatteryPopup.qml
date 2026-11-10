import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../.."

PanelWindow {
  id: popup
  property var battery: null
  property var toast: null
  property var powerProfiles: []
  property string activeProfile: ""
  property string pendingProfile: ""

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
              ? "PWR_DRAW\t// " + (popup.battery.isCharging ? "+" : "") + popup.battery.powerDraw/10 + "W"
              : popup.battery && popup.battery.powerDraw < 0
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

        Repeater {
          model: popup.powerProfiles
          delegate: Item {
            property string profileName: modelData
            property bool selected: profileName === popup.activeProfile
            property bool first: index === 0
            property bool last: index === popup.powerProfiles.length - 1
            Layout.fillWidth: true
            implicitHeight: 32

            Canvas {
              id: profileBackground
              anchors.fill: parent
              Connections {
                target: popup
                function onActiveProfileChanged() { profileBackground.requestPaint(); }
              }
              onPaint: {
                var ctx = getContext("2d");
                var cut = Theme.cornerCutSizeSmall;
                ctx.clearRect(0, 0, width, height);
                ctx.beginPath();
                ctx.moveTo(first ? 0 : 0, 0);
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
              onClicked: popup.selectProfile(profileName)
            }
          }
        }

        Text {
          visible: popup.powerProfiles.length === 0
          text: "POWER PROFILES // UNAVAILABLE"
          color: Theme.fgDim
          font.family: Theme.fontFamily
          font.pixelSize: 10
        }
      }
    }
  }

  Process {
    id: profileListProcess
    command: ["powerprofilesctl", "list"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        var profiles = [];
        var selected = "";
        text.split(/\r?\n/).forEach(function(line) {
          var match = line.match(/^(?:\s*\*\s+| {2})([a-z][a-z0-9_-]*)\s*:\s*$/i);
          if (match) {
            var profileName = match[1];
            if (profiles.indexOf(profileName) === -1) {
              profiles.push(profileName);
            }
            if (/^\s*\*/.test(line)) {
              selected = profileName;
            }
          }
        });
        profiles.reverse();
        popup.powerProfiles = profiles;
        popup.activeProfile = selected || (profiles.length > 0 ? profiles[0] : "");
      }
    }
    stderr: StdioCollector {}
  }

  Process {
    id: profileSetProcess
    command: ["powerprofilesctl", "set", popup.pendingProfile]
    onExited: function(exitCode) {
      if (exitCode === 0) {
        popup.activeProfile = popup.pendingProfile;
        popup.toast?.showToast("POWER // " + popup.pendingProfile.toUpperCase() + " ACTIVE", false);
        profileListProcess.running = true;
      } else {
        popup.toast?.showToast("POWER // PROFILE CHANGE FAILED", true);
      }
    }
  }

  function selectProfile(profile) {
    if (profile === activeProfile || profileSetProcess.running) {
      return;
    }
    pendingProfile = profile;
    profileSetProcess.running = true;
  }
}
