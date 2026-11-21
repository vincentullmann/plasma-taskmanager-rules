import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../code/tasks.js" as Tasks

ListView {
    id: list

    required property var tasksModel
    required property var store
    property bool vertical: false
    property int location: 0          // Plasmoid.location, places the tooltip
    property bool tooltips: true
    property var audio: null
    property var progress: null

    // Appearance (General settings page).
    property int iconSize: Kirigami.Units.iconSizes.medium
    property int fontSize: 0          // points, 0 = system default
    property int borderRadius: Kirigami.Units.cornerRadius
    property color backgroundColor: "transparent"
    property int padding: Kirigami.Units.smallSpacing
    property int gap: 0
    property int iconGap: Kirigami.Units.smallSpacing

    readonly property real maxButtonWidth: Kirigami.Units.gridUnit * 12
    readonly property real buttonHeight: iconSize + padding * 2
    readonly property real totalGaps: Math.max(0, count - 1) * gap

    // Size of one button along the list axis, gap included.
    readonly property real cellSize: vertical ? buttonHeight + gap
        : Math.min(maxButtonWidth, (width - totalGaps) / Math.max(1, count)) + gap

    // Live reorder while a button is dragged.
    function moveTask(from, to) {
        if (to !== from) tasksModel.move(from, to)
    }

    Layout.minimumWidth: vertical ? Kirigami.Units.gridUnit * 4 : 0
    Layout.preferredWidth: vertical ? Kirigami.Units.gridUnit * 8 : count * maxButtonWidth + totalGaps
    Layout.minimumHeight: vertical ? 0 : buttonHeight
    Layout.preferredHeight: vertical ? count * buttonHeight + totalGaps : buttonHeight
    Layout.fillWidth: true
    Layout.fillHeight: true

    orientation: vertical ? ListView.Vertical : ListView.Horizontal
    model: tasksModel
    interactive: false
    clip: true
    spacing: gap

    // Others slide aside while a button is dragged through them.
    move: Transition { NumberAnimation { properties: "x,y"; duration: Kirigami.Units.shortDuration } }
    displaced: Transition { NumberAnimation { properties: "x,y"; duration: Kirigami.Units.shortDuration } }

    delegate: TaskButton {
        tasksModel: list.tasksModel
        store: list.store
        audio: list.audio
        progress: list.progress
        vertical: list.vertical
        location: list.location
        tooltips: list.tooltips
        cellSize: list.cellSize
        count: list.count
        onMoveRequested: target => list.moveTask(index, target)
        iconSize: list.iconSize
        fontSize: list.fontSize
        borderRadius: list.borderRadius
        backgroundColor: list.backgroundColor
        padding: list.padding
        iconGap: list.iconGap
        width: list.vertical ? list.width : Math.min(list.maxButtonWidth, (list.width - list.totalGaps) / Math.max(1, list.count))
        height: list.vertical ? list.buttonHeight : list.height
    }
}
