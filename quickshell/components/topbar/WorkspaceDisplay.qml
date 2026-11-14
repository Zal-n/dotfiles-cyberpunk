import QtQuick
import Quickshell
import Quickshell.Io
import "../.."

Row {
    id: workspaceDisplay
    property var topbar
    property var moduleConfig: ({})
    readonly property var preset: topbar ? topbar.modulePreset(moduleConfig) : ({})
    property var workspaces: []
    spacing: preset.spacing ?? 6

    function workspaceIsFocused(workspace) {
        return workspace.is_focused === true || workspace.is_focused === "true";
    }

    Process {
        id: workspaceProcess
        command: ["niri", "msg", "-j", "workspaces"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var parsed = JSON.parse(text);
                    if (!Array.isArray(parsed)) {
                        workspaceDisplay.workspaces = [];
                    } else {
                        parsed.sort(function(left, right) {
                            return Number(left.idx ?? left.id ?? 0) - Number(right.idx ?? right.id ?? 0);
                        });
                        workspaceDisplay.workspaces = parsed;
                    }
                } catch (e) {
                    workspaceDisplay.workspaces = [];
                }
            }
        }
    }

    Process {
        id: workspaceEvents
        command: ["niri", "msg", "--json", "event-stream"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(data) {
                var event;
                try {
                    event = JSON.parse(data);
                } catch (e) {
                    return;
                }

                var eventNames = Object.keys(event);
                var workspaceEvent = eventNames.some(function(name) {
                    return name.indexOf("Workspace") !== -1;
                });
                if (workspaceEvent && !workspaceProcess.running) {
                    workspaceProcess.running = true;
                }
            }
        }
        onRunningChanged: {
            if (!running) {
                running = true;
            }
        }
    }

    Process {
        id: focusWorkspaceProcess
        command: []
    }

    function focusWorkspace(workspace) {
        var target = workspace.idx ?? workspace.id;
        if (target === undefined || target === null || focusWorkspaceProcess.running) {
            return;
        }
        focusWorkspaceProcess.command = ["niri", "msg", "action", "focus-workspace", String(target)];
        focusWorkspaceProcess.running = true;
    }

    Repeater {
        model: workspaceDisplay.workspaces
        delegate: Loader {
            property var workspace: modelData
            property var workspacePreset: workspaceDisplay.topbar
                ? workspaceDisplay.topbar.modulePreset(workspaceDisplay.moduleConfig)
                : ({})
            sourceComponent: {
                switch (workspacePreset.style ?? "dots") {
                case "numbers":
                    return numberWorkspace;
                case "rectangles":
                    return rectangleWorkspace;
                default:
                    return dotWorkspace;
                }
            }
            onLoaded: {
                item.workspace = workspace;
                item.preset = workspacePreset;
            }
        }
    }

    Component {
        id: dotWorkspace
        Rectangle {
            property var workspace: ({})
            property var preset: ({})
            width: preset.size ?? 7
            height: width
            radius: width / 2
            color: workspaceDisplay.workspaceIsFocused(workspace)
                ? workspaceDisplay.topbar.presetColor(preset.activeColor)
                : workspaceDisplay.topbar.presetColor(preset.inactiveColor)

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: workspaceDisplay.focusWorkspace(parent.workspace)
            }
        }
    }

    Component {
        id: rectangleWorkspace
        Rectangle {
            property var workspace: ({})
            property var preset: ({})
            width: preset.width ?? 16
            height: preset.height ?? 5
            color: workspaceDisplay.workspaceIsFocused(workspace)
                ? workspaceDisplay.topbar.presetColor(preset.activeColor)
                : workspaceDisplay.topbar.presetColor(preset.inactiveColor)

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: workspaceDisplay.focusWorkspace(parent.workspace)
            }
        }
    }

    Component {
        id: numberWorkspace
        Text {
            property var workspace: ({})
            property var preset: ({})
            text: workspace.idx ?? workspace.id ?? "?"
            color: workspaceDisplay.workspaceIsFocused(workspace)
                ? workspaceDisplay.topbar.presetColor(preset.activeColor)
                : workspaceDisplay.topbar.presetColor(preset.inactiveColor)
            font.family: Theme.fontFamily
            font.pixelSize: preset.fontSize ?? 11

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: workspaceDisplay.focusWorkspace(parent.workspace)
            }
        }
    }
}
