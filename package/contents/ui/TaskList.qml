import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

ListView {
    id: list

    required property var tasksModel
    property bool vertical: false

    readonly property real maxButtonWidth: Kirigami.Units.gridUnit * 12
    readonly property real buttonHeight: Kirigami.Units.iconSizes.medium + Kirigami.Units.smallSpacing * 2

    Layout.minimumWidth: vertical ? Kirigami.Units.gridUnit * 4 : 0
    Layout.preferredWidth: vertical ? Kirigami.Units.gridUnit * 8 : count * maxButtonWidth
    Layout.minimumHeight: vertical ? 0 : buttonHeight
    Layout.preferredHeight: vertical ? count * buttonHeight : buttonHeight
    Layout.fillWidth: true
    Layout.fillHeight: true

    orientation: vertical ? ListView.Vertical : ListView.Horizontal
    model: tasksModel
    interactive: false
    clip: true
    spacing: 0

    delegate: TaskButton {
        tasksModel: list.tasksModel
        width: list.vertical ? list.width : Math.min(list.maxButtonWidth, list.width / Math.max(1, list.count))
        height: list.vertical ? list.buttonHeight : list.height
    }
}
