import QtQml

QtObject {
    property string kind: "generic"
    property real gridWidth: 1
    property real gridHeight: 1
    property real compactWidthThreshold: 1
    property real compactHeightThreshold: 1
    property real verticalWidthThreshold: 3
    property real verticalHeightThreshold: 2

    readonly property bool compact: gridWidth <= compactWidthThreshold
        && gridHeight <= compactHeightThreshold
    readonly property bool vertical: !compact
        && kind === "slider"
        && gridWidth <= verticalWidthThreshold
        && gridHeight >= verticalHeightThreshold
    readonly property bool horizontal: !compact
        && gridHeight <= compactHeightThreshold
        && gridWidth > compactWidthThreshold
    readonly property bool detail: !compact && !vertical && !horizontal
    readonly property string mode: compact ? "compact"
        : vertical ? "vertical"
        : horizontal ? "horizontal"
        : "detail"
}
