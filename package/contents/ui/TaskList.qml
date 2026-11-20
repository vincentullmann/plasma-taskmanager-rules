import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

ListView {
    id: list

    required property var tasksModel
    required property var store
    property bool vertical: false

    // Appearance (General settings page).
    property int iconSize: Kirigami.Units.iconSizes.medium
    property int fontSize: 0          // points, 0 = system default
    property int borderRadius: Kirigami.Units.cornerRadius
    property int padding: Kirigami.Units.smallSpacing
    property int gap: 0

    readonly property real maxButtonWidth: Kirigami.Units.gridUnit * 12
    readonly property real buttonHeight: iconSize + padding * 2
    readonly property real totalGaps: Math.max(0, count - 1) * gap

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
        iconSize: list.iconSize
        fontSize: list.fontSize
        borderRadius: list.borderRadius
        padding: list.padding
        width: list.vertical ? list.width : Math.min(list.maxButtonWidth, (list.width - list.totalGaps) / Math.max(1, list.count))
        height: list.vertical ? list.buttonHeight : list.height
    }
}
