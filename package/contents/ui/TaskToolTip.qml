import QtQuick
import org.kde.plasma.core as PlasmaCore

// Plasma's own tooltip: a real tooltip window that never sits under the pointer, so it doesn't flicker.
// Kept in its own file so headless tests (tooltips: false) never import plasma.core.
PlasmaCore.ToolTipArea {
    property var button: null
    mainText: button ? button.tooltipLabel : ""
    subText: button ? button.tooltipSubText : ""
    textFormat: Text.RichText
    location: button ? button.location : 0
    active: button !== null && !button.dragging && !button.menuOpen
}
