pragma Singleton
import QtQuick
import Quickshell

QtObject {
  property var rawConfig: ({})

  readonly property color bg: rawConfig.theme?.bg ?? "#0a0b10"
  readonly property color surface: rawConfig.theme?.surface ?? "#121520"
  readonly property color surfaceAccent: rawConfig.theme?.surfaceAccent ?? "#1a1e2d"
  readonly property color cyan: rawConfig.theme?.cyan ?? "#00f0ff"
  readonly property color magenta: rawConfig.theme?.magenta ?? "#ff0055"
  readonly property color yellow: rawConfig.theme?.yellow ?? "#ffe600"
  readonly property color fg: rawConfig.theme?.fg ?? "#e0e6ed"
  readonly property color fgDim: rawConfig.theme?.fgDim ?? "#565f89"
  readonly property string fontFamily: rawConfig.theme?.fontFamily ?? "JetBrainsMono Nerd Font"

  readonly property int barHeight: rawConfig.desktop?.barHeight ?? 38
  readonly property int cornerCutSize: rawConfig.desktop?.cornerCutSize ?? 25
  readonly property string wallpaper: rawConfig.desktop?.wallpaper ? rawConfig.desktop.wallpaper : ""
}
