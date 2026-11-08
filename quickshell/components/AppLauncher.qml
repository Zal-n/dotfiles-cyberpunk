import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import ".."

PanelWindow {
    id: launcher
    signal closeRequested()

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    anchors { top: true; bottom: true; left: true; right: true }
    color: "#cc0a0b10"

    // Lecsapott sarkú Cyberpunk háttér (Jobb alsó sarok)
    Item {
        anchors.centerIn: parent
        implicitWidth: 600
        implicitHeight: 450

        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d");
                var cut = 30;
                ctx.clearRect(0, 0, width, height);
                ctx.beginPath();

                ctx.moveTo(0, 0);
                ctx.lineTo(width, 0);
                ctx.lineTo(width, height);
                ctx.lineTo(cut, height);
                ctx.lineTo(0, height-cut);

                ctx.closePath();

                ctx.fillStyle = Theme.bg;
                ctx.fill();
                ctx.lineWidth = 2;
                ctx.strokeStyle = Theme.cyan;
                ctx.stroke();
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            // Input Mező
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 45
                color: Theme.surface
                //border.color: Theme.magenta
                border.width: 1

                Canvas {
                    anchors.fill: parent
                    onPaint: {
                    var ctx = getContext("2d");
                    var cut = 15;
                    ctx.clearRect(0, 0, width, height);
                    ctx.beginPath();

                    ctx.moveTo(0, 0);
                    ctx.lineTo(width, 0);
                    ctx.lineTo(width, height);
                    ctx.lineTo(cut, height);
                    ctx.lineTo(0, height-cut);

                    ctx.closePath();

                    ctx.fillStyle = Theme.surface;
                    ctx.fill();
                    ctx.lineWidth = 2;
                    ctx.strokeStyle = Theme.magenta;
                    ctx.stroke();
            }
        }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    Text { text: "EXEC //"; color: Theme.yellow; font.family: Theme.fontFamily; font.bold: true }
                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        color: Theme.cyan
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        focus: launcher.visible
                        onTextChanged: filterModel(text)
                        onAccepted: {
                            if (filteredList.count > 0) {
                                var cmd = filteredList.get(0).exec;
                                launcherProc.command = ["sh", "-c", cmd + " &"];
                                launcherProc.running = true;
                                launcher.closeRequested();
                            } else if (text.length > 0) {
                                launcherProc.command = ["sh", "-c", text + " &"];
                                launcherProc.running = true;
                                launcher.closeRequested();
                            }
                        }
                    }
                }
            }

            // Szűrt App Lista
            ListView {
                id: appList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: filteredList

                delegate: Rectangle {
                    implicitWidth: appList.width
                    implicitHeight: 40
                    color: itemArea.containsMouse ? Theme.surfaceAccent : "transparent"
                    border.color: itemArea.containsMouse ? Theme.cyan : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10
                        Text {
                            text: model.name
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: model.exec
                            color: Theme.fgDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }
                    }

                    MouseArea {
                        id: itemArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            launcherProc.command = ["sh", "-c", model.exec + " &"];
                            launcherProc.running = true;
                            launcher.closeRequested();
                        }
                    }
                }
            }
        }
    }

    // App adatbázis és szűrés
    ListModel { id: fullList }
    ListModel { id: filteredList }

    Process { id: launcherProc }

    function filterModel(query) {
        filteredList.clear();
        var q = query.toLowerCase();
        for (var i = 0; i < fullList.count; i++) {
            var item = fullList.get(i);
            if (q === "" || item.name.toLowerCase().indexOf(q) !== -1 || item.exec.toLowerCase().indexOf(q) !== -1) {
                filteredList.append(item);
            }
        }
    }

    Component.onCompleted: {
        var apps = [
            { name: "Terminal (Kitty)", exec: "kitty" },
            { name: "Browser (Firefox)", exec: "firefox" },
            { name: "System Monitor (Btop)", exec: "kitty -e btop" },
            { name: "Fastfetch", exec: "kitty -e fastfetch" },
            { name: "File Manager (Yazi)", exec: "kitty -e yazi" },
            { name: "Code Editor", exec: "code" },
            { name: "Discord", exec: "discord" },
            { name: "Steam", exec: "steam" }
        ];
        for (var i = 0; i < apps.length; i++) {
            fullList.append(apps[i]);
        }
        filterModel("");
    }

    Shortcut {
        sequence: "Escape"
        onActivated: launcher.closeRequested()
    }
}