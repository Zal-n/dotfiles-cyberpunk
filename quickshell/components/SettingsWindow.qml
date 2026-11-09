import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".."

PanelWindow {
    id: settingsWin
    signal closeRequested()

    property var cfg: root.config

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "#aa0a0b10"

    Rectangle {
        anchors.centerIn: parent
        implicitWidth: 800
        implicitHeight: 520
        color: Theme.bg
        border.color: Theme.cyan
        border.width: 2

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // Oldalsáv (Tabs)
            Rectangle {
                implicitWidth: 200
                Layout.fillHeight: true
                color: Theme.surface
                border.color: Theme.surfaceAccent
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Text { 
                        text: "SETTINGS // CORE"
                        color: Theme.yellow
                        font.family: Theme.fontFamily
                        font.bold: true 
                    }

                    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.surfaceAccent }

                    Repeater {
                        model: ["Display & OLED", "Themes & Palette", "Wallpaper", "Keybindings"]
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 36
                            color: tabArea.containsMouse ? Theme.surfaceAccent : "transparent"
                            border.color: tabArea.containsMouse ? Theme.cyan : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                            }

                            MouseArea { id: tabArea; anchors.fill: parent; hoverEnabled: true }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 32
                        color: Theme.magenta
                        Text { 
                            anchors.centerIn: parent
                            text: "CLOSE"
                            color: Theme.bg
                            font.family: Theme.fontFamily
                            font.bold: true 
                        }
                        MouseArea { anchors.fill: parent; onClicked: settingsWin.closeRequested() }
                    }
                }
            }

            // Fő beállítási felület
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Theme.bg

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 16

                    Text { 
                        text: "DISPLAY CONFIGURATION (Intel iGPU / 165Hz)"
                        color: Theme.cyan
                        font.family: Theme.fontFamily
                        font.bold: true 
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 80
                        color: Theme.surface
                        border.color: Theme.cyan
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            Text { text: "Output: eDP-1 | 1920x1080 @ 165Hz"; color: Theme.fg; font.family: Theme.fontFamily }
                            Text { text: "VRR / Variable Refresh Rate: Enabled"; color: Theme.yellow; font.family: Theme.fontFamily; font.pixelSize: 11 }
                        }
                    }

                    Text { 
                        text: "WALLPAPER PATH"
                        color: Theme.cyan
                        font.family: Theme.fontFamily
                        font.bold: true 
                    }

                    RowLayout {
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 36
                            color: Theme.surface
                            border.color: Theme.magenta
                            border.width: 1
                            TextInput {
                                id: wpInput
                                anchors.fill: parent
                                anchors.margins: 8
                                text: Theme.wallpaper
                                color: Theme.fg
                                font.family: Theme.fontFamily
                            }
                        }
                        Rectangle {
                            implicitWidth: 80
                            implicitHeight: 36
                            color: Theme.cyan
                            Text { 
                                anchors.centerIn: parent
                                text: "APPLY"
                                color: Theme.bg
                                font.family: Theme.fontFamily
                                font.bold: true 
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    root.config.desktop.wallpaper = wpInput.text;
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }
    }
}
