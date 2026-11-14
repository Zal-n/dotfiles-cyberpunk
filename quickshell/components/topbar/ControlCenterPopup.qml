import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../controlcenter"
import "../.."

PanelWindow {
    id: cc

    signal closeRequested()
    signal openSettingsRequested()
    property var topbar: null
    property var toast: null

    readonly property var defaultConfig: ({
        "width": 420,
        "height": 520,
        "columns": 12,
        "rowHeight": 64,
        "moduleGap": 4,
        "modules": [
            { "id": "wifi", "type": "wifi", "x": 0, "y": 0, "w": 6, "h": 2 },
            { "id": "audio", "type": "audio", "x": 6, "y": 0, "w": 6, "h": 2 },
            { "id": "microphone", "type": "microphone", "x": 0, "y": 2, "w": 4, "h": 2 },
            { "id": "brightness", "type": "brightness", "x": 4, "y": 2, "w": 8, "h": 2 },
            { "id": "bluetooth", "type": "bluetooth", "x": 0, "y": 4, "w": 4, "h": 2 },
            { "id": "background-apps", "type": "background_apps", "x": 4, "y": 4, "w": 8, "h": 2 }
        ]
    })
    property var ccConfig: root.config.desktop?.controlCenter ?? defaultConfig
    property var modules: ccConfig.modules ?? defaultConfig.modules
    property var editModules: []
    property bool editMode: false
    property bool addMenuOpen: false
    readonly property real moduleGap: Number(ccConfig.moduleGap ?? 4)
    property real resizeStartWidth: 0
    property real resizeStartHeight: 0
    property real editWidth: 0
    property real editHeight: 0
    property real popupWidth: Math.max(320, Number(ccConfig.width ?? defaultConfig.width))
    property real popupHeight: Math.max(300, Number(ccConfig.height ?? defaultConfig.height))
    readonly property real resizeStep: 0.5
    readonly property real minimumCellWidth: 28

    visible: root.controlCenterOpen
    WlrLayershell.layer: WlrLayer.Overlay
    anchors {
        top: true
        right: true
    }
    margins.top: Theme.barHeight
    margins.right: 0
    implicitWidth: popupWidth
    implicitHeight: popupHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    onVisibleChanged: {
        if (!visible && editMode) cancelEdit();
    }

    Item {
        id: surface
        anchors.fill: parent

        Canvas {
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
                ctx.lineWidth = 2;
                ctx.strokeStyle = Theme.cyan;
                ctx.stroke();
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: editMode ? "CONTROL CENTER // EDIT" : "CONTROL CENTER"
                    color: Theme.yellow
                    font.family: Theme.fontFamily
                    font.bold: true
                    font.pixelSize: 12
                }
                Item { Layout.fillWidth: true }
                Text {
                    visible: editMode
                    text: addMenuOpen ? "×" : "+"
                    color: Theme.cyan
                    font.family: Theme.fontFamily
                    font.bold: true
                    font.pixelSize: 20
                    MouseArea {
                        anchors.fill: parent
                        onClicked: cc.addMenuOpen = !cc.addMenuOpen
                    }
                }
                Text {
                    text: editMode ? "DONE" : "EDIT"
                    color: editMode ? Theme.cyan : Theme.magenta
                    font.family: Theme.fontFamily
                    font.bold: true
                    MouseArea {
                        anchors.fill: parent
                        onClicked: cc.toggleEditMode()
                    }
                }
                Text {
                    text: "[X]"
                    color: Theme.magenta
                    font.family: Theme.fontFamily
                    font.bold: true
                    MouseArea {
                        anchors.fill: parent
                        onClicked: cc.requestClose()
                    }
                }
            }

            Item {
                id: moduleArea
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                Repeater {
                    model: cc.editMode ? cc.editModules : cc.modules
                    delegate: Item {
                        id: card
                        property var module: modelData
                        property real startX: 0
                        property real startY: 0
                        property real startWidth: 0
                        property real startHeight: 0
                        property real grabOffsetX: 0
                        property real grabOffsetY: 0
                        property real resizePointerStartX: 0
                        property real resizePointerStartY: 0
                        property real previewX: Number(module.x ?? 0)
                        property real previewY: Number(module.y ?? 0)
                        property real previewW: Number(module.w ?? 1)
                        property real previewH: Number(module.h ?? 1)
                        x: Number(module.x ?? 0) * cc.cellPitch
                        y: Number(module.y ?? 0) * cc.rowHeight
                        width: Math.max(48, cc.spanPixels(Number(module.w ?? 1)))
                        height: Math.max(40, cc.spanPixels(Number(module.h ?? 1), cc.rowHeight))

                        Rectangle {
                            anchors.fill: parent
                            color: Theme.surface
                            border.color: cc.editMode ? Theme.yellow : Theme.surfaceAccent
                            border.width: cc.editMode ? 2 : 1
                        }

                        Loader {
                            id: moduleLoader
                            anchors.fill: parent
                            anchors.margins: 10
                            sourceComponent: cc.moduleComponent(card.module.type)
                            Binding {
                                target: moduleLoader.item
                                property: "gridWidth"
                                value: card.previewW
                                when: moduleLoader.status === Loader.Ready
                            }
                            Binding {
                                target: moduleLoader.item
                                property: "gridHeight"
                                value: card.previewH
                                when: moduleLoader.status === Loader.Ready
                            }
                        }

                        Text {
                            visible: cc.editMode
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 2
                            text: "×"
                            color: Theme.magenta
                            font.bold: true
                            font.pixelSize: 22
                            width: 28
                            height: 28
                            z: 3
                            MouseArea {
                                anchors.fill: parent
                                onClicked: cc.removeModule(card.module.id)
                            }
                        }

                        MouseArea {
                            id: dragArea
                            visible: cc.editMode
                            anchors.fill: parent
                            anchors.rightMargin: 20
                            preventStealing: true
                            z: 2
                            onPressed: {
                                card.startX = card.x;
                                card.startY = card.y;
                                card.startWidth = card.width;
                                card.startHeight = card.height;
                                card.previewX = Number(card.module.x ?? 0);
                                card.previewY = Number(card.module.y ?? 0);
                                card.previewW = Number(card.module.w ?? 1);
                                card.previewH = Number(card.module.h ?? 1);
                                var pointer = moduleArea.mapFromItem(dragArea, mouse.x, mouse.y);
                                card.grabOffsetX = pointer.x - card.x;
                                card.grabOffsetY = pointer.y - card.y;
                            }
                            onPositionChanged: function(mouse) {
                                if (!pressed) return;
                                var pointer = moduleArea.mapFromItem(dragArea, mouse.x, mouse.y);
                                var columns = Number(ccConfig.columns ?? 12);
                                var nextX = Math.max(0, Math.min(
                                    columns - card.previewW,
                                    cc.snap((pointer.x - card.grabOffsetX) / cc.cellPitch)
                                ));
                                var nextY = Math.max(0, cc.snap(
                                    (pointer.y - card.grabOffsetY) / cc.rowHeight
                                ));
                                var candidate = {
                                    "id": card.module.id,
                                    "x": nextX,
                                    "y": nextY,
                                    "w": card.previewW,
                                    "h": card.previewH
                                };
                                if (cc.canPlace(candidate)) {
                                    card.previewX = nextX;
                                    card.previewY = nextY;
                                    card.x = nextX * cc.cellPitch;
                                    card.y = nextY * cc.rowHeight;
                                }
                            }
                            onReleased: cc.commitCard(card)
                        }

                        Rectangle {
                            visible: cc.editMode
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            width: 18
                            height: 18
                            color: Theme.magenta
                            z: 4
                            Text {
                                anchors.centerIn: parent
                                text: "↘"
                                color: Theme.bg
                                font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                preventStealing: true
                                onPressed: {
                                    card.startX = card.x;
                                    card.startY = card.y;
                                    card.startWidth = card.width;
                                    card.startHeight = card.height;
                                    card.previewX = Number(card.module.x ?? 0);
                                    card.previewY = Number(card.module.y ?? 0);
                                    card.previewW = Number(card.module.w ?? 1);
                                    card.previewH = Number(card.module.h ?? 1);
                                    var pointer = moduleArea.mapFromItem(parent, mouse.x, mouse.y);
                                    card.resizePointerStartX = pointer.x;
                                    card.resizePointerStartY = pointer.y;
                                }
                                onPositionChanged: function(mouse) {
                                    if (!pressed) return;
                                    var pointer = moduleArea.mapFromItem(parent, mouse.x, mouse.y);
                                    var nextW = cc.spanFromPixels(
                                        card.startWidth + pointer.x - card.resizePointerStartX
                                    );
                                    var nextH = cc.spanFromPixels(
                                        card.startHeight + pointer.y - card.resizePointerStartY,
                                        cc.rowHeight
                                    );
                                    var candidate = {
                                        "id": card.module.id,
                                        "x": card.previewX,
                                        "y": card.previewY,
                                        "w": nextW,
                                        "h": nextH
                                    };
                                    if (cc.canPlace(candidate)) {
                                        card.previewW = nextW;
                                        card.previewH = nextH;
                                        card.width = Math.max(48, cc.spanPixels(nextW));
                                        card.height = Math.max(40, cc.spanPixels(nextH, cc.rowHeight));
                                    }
                                }
                                onReleased: cc.commitCard(card)
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: addMenu
            property var owner: cc
            property var availableModules: cc.availableModuleCatalog()
            visible: cc.editMode && cc.addMenuOpen
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 42
            width: 190
            height: Math.min(260, addMenuColumn.implicitHeight + 16)
            color: Theme.surface
            border.color: Theme.cyan
            border.width: 1
            z: 10

            Column {
                id: addMenuColumn
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4

                Repeater {
                    model: addMenu.availableModules
                    delegate: Rectangle {
                        required property var modelData
                        width: addMenuColumn.width
                        height: 28
                        color: addItemArea.containsMouse ? Theme.surfaceAccent : "transparent"
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.label
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }
                        MouseArea {
                            id: addItemArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                addMenu.owner.addModule(modelData.id);
                                addMenu.owner.addMenuOpen = false;
                            }
                        }
                    }
                }

                Text {
                    visible: addMenu.availableModules.length === 0
                    text: "NO MODULES AVAILABLE"
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
            }
        }

        MouseArea {
            visible: cc.editMode
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: 22
            height: 22
            cursorShape: Qt.SizeFDiagCursor
            onPressed: {
                cc.resizeStartWidth = cc.width;
                cc.resizeStartHeight = cc.height;
            }
            onPositionChanged: function(mouse) {
                if (!pressed) return;
                cc.resizePopup(resizeStartWidth + mouse.x, resizeStartHeight + mouse.y);
            }
            onReleased: {
                cc.editWidth = cc.width;
                cc.editHeight = cc.height;
            }
        }
    }

    readonly property real cellWidth: (moduleArea.width - (Number(ccConfig.columns ?? 12) - 1) * moduleGap)
        / Number(ccConfig.columns ?? 12)
    readonly property real cellPitch: cellWidth + moduleGap
    readonly property int rowHeight: Number(ccConfig.rowHeight ?? 64)

    function snap(value) {
        return Math.max(0, Math.round(value / resizeStep) * resizeStep);
    }

    function spanPixels(span, unit) {
        if (unit !== undefined) return Math.max(1, span * unit - moduleGap);
        var cell = cellWidth;
        return span * cell + Math.max(0, Math.ceil(span) - 1) * moduleGap;
    }

    function spanFromPixels(pixels, unit) {
        var best = resizeStep;
        var distance = Infinity;
        for (var span = resizeStep; span <= Number(ccConfig.columns ?? 12); span += resizeStep) {
            var nextDistance = Math.abs(
                (unit === undefined ? spanPixels(span) : spanPixels(span, unit)) - pixels
            );
            if (nextDistance < distance) {
                best = span;
                distance = nextDistance;
            }
        }
        return best;
    }

    function moduleComponent(type) {
        switch (type) {
        case "wifi": return wifiModule;
        case "audio": return audioModule;
        case "microphone": return microphoneModule;
        case "brightness": return brightnessModule;
        case "bluetooth": return bluetoothModule;
        case "background_apps": return backgroundAppsModule;
        case "power": return powerModule;
        default: return null;
        }
    }

    function toggleEditMode() {
        if (!editMode) {
            editModules = JSON.parse(JSON.stringify(modules));
            fitPopupToLayout(editModules);
            editWidth = popupWidth;
            editHeight = popupHeight;
            editMode = true;
            return;
        }
        fitPopupToLayout(editModules);
        persistLayout(editModules, popupWidth, popupHeight);
        addMenuOpen = false;
        editMode = false;
    }

    function resizePopup(nextWidth, nextHeight) {
        popupWidth = Math.max(320, Math.min(800, nextWidth));
        popupHeight = Math.max(300, Math.min(900, nextHeight));
        editWidth = popupWidth;
        editHeight = popupHeight;
    }

    function fitPopupToLayout(layout) {
        var maxColumn = 0;
        var maxRow = 0;
        for (var i = 0; i < layout.length; i++) {
            maxColumn = Math.max(maxColumn,
                Number(layout[i].x ?? 0) + Number(layout[i].w ?? 1));
            maxRow = Math.max(maxRow,
                Number(layout[i].y ?? 0) + Number(layout[i].h ?? 1));
        }
        var desiredWidth = 28 + maxColumn * (minimumCellWidth + moduleGap) - moduleGap;
        var desiredHeight = 80 + maxRow * rowHeight;
        resizePopup(Math.max(320, desiredWidth), Math.max(300, desiredHeight));
    }

    function commitCard(card) {
        var columns = Number(ccConfig.columns ?? 12);
        var nextX = Math.max(0, Math.min(columns - card.previewW, snap(card.x / cellPitch)));
        var nextY = Math.max(0, snap(card.y / rowHeight));
        var nextW = Math.max(resizeStep, Math.min(columns - nextX, card.previewW));
        var nextH = Math.max(resizeStep, card.previewH);
        var candidate = { "id": card.module.id, "x": nextX, "y": nextY, "w": nextW, "h": nextH };
        if (!cc.canPlace(candidate)) {
            card.x = card.startX;
            card.y = card.startY;
            card.width = card.startWidth;
            card.height = card.startHeight;
            toast?.showToast("CONTROL // SPACE OCCUPIED", true);
            return;
        }
        updateWorkingModule(card.module.id, { "x": nextX, "y": nextY, "w": nextW, "h": nextH });
    }

    function canPlace(candidate) {
        var sourceModules = editMode ? editModules : modules;
        for (var i = 0; i < sourceModules.length; i++) {
            var other = sourceModules[i];
            if (other.id === candidate.id) continue;
            var separated = candidate.x + candidate.w <= other.x
                || other.x + other.w <= candidate.x
                || candidate.y + candidate.h <= other.y
                || other.y + other.h <= candidate.y;
            if (!separated) return false;
        }
        return candidate.x >= 0
            && candidate.y >= 0
            && candidate.w > 0
            && candidate.h > 0
            && candidate.x + candidate.w <= Number(ccConfig.columns ?? 12);
    }

    function findPlacement(width, height) {
        var columns = Number(ccConfig.columns ?? 12);
        var rows = Math.max(12, Math.ceil(moduleArea.height / rowHeight) + 4);
        for (var y = 0; y < rows; y += resizeStep) {
            for (var x = columns - width; x >= 0; x -= resizeStep) {
                var candidate = { "id": "__new__", "x": x, "y": y, "w": width, "h": height };
                if (cc.canPlace(candidate)) return candidate;
            }
        }
        return null;
    }

    function updateWorkingModule(id, changes) {
        var nextModules = JSON.parse(JSON.stringify(editModules));
        for (var i = 0; i < nextModules.length; i++) {
            if (nextModules[i].id === id) {
                Object.keys(changes).forEach(function(key) {
                    nextModules[i][key] = changes[key];
                });
            }
        }
        editModules = nextModules;
    }

    function persistLayout(nextModules, nextWidth, nextHeight) {
        var cfg = JSON.parse(JSON.stringify(root.config));
        cfg.desktop = cfg.desktop ?? {};
        cfg.desktop.controlCenter = JSON.parse(JSON.stringify(ccConfig));
        cfg.desktop.controlCenter.modules = nextModules;
        cfg.desktop.controlCenter.width = nextWidth;
        cfg.desktop.controlCenter.height = nextHeight;
        root.saveConfig(cfg);
    }

    function removeModule(id) {
        editModules = editModules.filter(function(module) { return module.id !== id; });
    }

    function moduleCatalog() {
        return [
            { "id": "wifi", "type": "wifi", "label": "Wi-Fi", "w": 6, "h": 2 },
            { "id": "audio", "type": "audio", "label": "Audio", "w": 6, "h": 2 },
            { "id": "microphone", "type": "microphone", "label": "Microphone", "w": 4, "h": 2 },
            { "id": "brightness", "type": "brightness", "label": "Brightness", "w": 8, "h": 2 },
            { "id": "bluetooth", "type": "bluetooth", "label": "Bluetooth", "w": 4, "h": 2 },
            { "id": "background-apps", "type": "background_apps", "label": "Background apps", "w": 8, "h": 2 },
            { "id": "power", "type": "power", "label": "Power", "w": 8, "h": 2 }
        ];
    }

    function availableModuleCatalog() {
        var available = [];
        moduleCatalog().forEach(function(candidate) {
            if (editModules.some(function(module) { return module.id === candidate.id; })) return;
            available.push(candidate);
        });
        return available;
    }

    function addModule(id) {
        var available = moduleCatalog();
        for (var i = 0; i < available.length; i++) {
            if (available[i].id === id) {
                var next = {
                    "id": available[i].id,
                    "type": available[i].type,
                    "x": 0,
                    "y": 0,
                    "w": available[i].w,
                    "h": available[i].h
                };
                var placement = cc.findPlacement(next.w, next.h);
                if (!placement) {
                    toast?.showToast("CONTROL // NO SPACE", true);
                    return;
                }
                next.x = placement.x;
                next.y = placement.y;
                var requiredHeight = (placement.y + next.h) * rowHeight + 80;
                var nextHeight = Math.max(popupHeight, requiredHeight);
                editModules = editModules.concat([next]);
                resizePopup(popupWidth, nextHeight);
                return;
            }
        }
    }

    function requestClose() {
        if (editMode) cancelEdit();
        closeRequested();
    }

    function cancelEdit() {
        editModules = [];
        addMenuOpen = false;
        editMode = false;
        popupWidth = Math.max(320, Number(ccConfig.width ?? defaultConfig.width));
        popupHeight = Math.max(300, Number(ccConfig.height ?? defaultConfig.height));
    }

    Component { id: wifiModule; WifiModule { topbar: cc.topbar } }
    Component { id: audioModule; AudioModule { topbar: cc.topbar } }
    Component { id: microphoneModule; MicrophoneModule {} }
    Component { id: brightnessModule; BrightnessModule { id: brightnessModuleItem } }
    Component { id: bluetoothModule; BluetoothModule {} }
    Component { id: backgroundAppsModule; BackgroundAppsModule {} }
    Component { id: powerModule; PowerModule {} }
}
