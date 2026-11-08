import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

PanelWindow {
    id: bgWindow
    property string wallpaperPath: ""

    WlrLayershell.layer: WlrLayer.Background

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: Theme.bg

    // Fallback Cyberpunk Grid Pattern (ha nincs háttérkép megadva)
    Canvas {
        anchors.fill: parent
        visible: bgWindow.wallpaperPath === ""
        onPaint: {
            var ctx = getContext("2d");
            ctx.strokeStyle = "#121520";
            ctx.lineWidth = 1;
            var step = 40;
            for (var x = 0; x < width; x += step) {
                ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, height); ctx.stroke();
            }
            for (var y = 0; y < height; y += step) {
                ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke();
            }
        }
    }

    // Háttérkép megjelenítés
Image {
    anchors.fill: parent
    source: {
        if (bgWindow.wallpaperPath === "") return "";
        if (bgWindow.wallpaperPath.startsWith("/")) return "file://" + bgWindow.wallpaperPath;
        return bgWindow.wallpaperPath;
    }
    fillMode: Image.PreserveAspectCrop
    visible: bgWindow.wallpaperPath !== ""
    asynchronous: true
}
}