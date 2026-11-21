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

    readonly property real maxButtonWidth: Kirigami.Units.gridUnit * 12
    readonly property real buttonHeight: iconSize + padding * 2
    readonly property real totalGaps: Math.max(0, count - 1) * gap

    // Size of one button along the list axis, gap included.
    readonly property real cellSize: vertical ? buttonHeight + gap
        : Math.min(maxButtonWidth, (width - totalGaps) / Math.max(1, count)) + gap

    // Where a button ends up when dragged `translation` px along the axis from `from`.
    function dropTarget(from, translation) {
        return Tasks.dropIndex(from * cellSize + cellSize / 2 + translation, cellSize, count)
    }

    function commitDrag(from, translation) {
        const to = dropTarget(from, translation)
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

    delegate: TaskButton {
        tasksModel: list.tasksModel
        store: list.store
        audio: list.audio
        progress: list.progress
        vertical: list.vertical
        location: list.location
        tooltips: list.tooltips
        onDragFinished: translation => list.commitDrag(index, translation)
        iconSize: list.iconSize
        fontSize: list.fontSize
        borderRadius: list.borderRadius
        backgroundColor: list.backgroundColor
        padding: list.padding
        width: list.vertical ? list.width : Math.min(list.maxButtonWidth, (list.width - list.totalGaps) / Math.max(1, list.count))
        height: list.vertical ? list.buttonHeight : list.height
    }
}
