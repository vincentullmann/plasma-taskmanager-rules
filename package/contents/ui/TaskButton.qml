import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

// One window. Roles come from TaskManager.TasksModel.
Item {
    id: button

    required property var tasksModel
    required property int index
    required property var model

    readonly property bool active: model.IsActive === true
    readonly property bool minimized: model.IsMinimized === true
    readonly property bool attention: model.IsDemandingAttention === true

    function modelIndex() {
        return tasksModel.makeModelIndex(index)
    }

    Rectangle {
        id: background
        anchors.fill: parent
        anchors.margins: 1
        radius: Kirigami.Units.cornerRadius
        color: button.attention ? Kirigami.Theme.neutralTextColor
             : button.active ? Kirigami.Theme.highlightColor
             : Kirigami.Theme.textColor
        opacity: button.attention ? 0.35
               : button.active ? 0.30
               : mouse.containsMouse ? 0.12 : 0
        Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }
    }

    // Active marker.
    Rectangle {
        visible: button.active
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 1 }
        height: 2
        color: Kirigami.Theme.highlightColor
    }

    Row {
        anchors { fill: parent; leftMargin: Kirigami.Units.smallSpacing; rightMargin: Kirigami.Units.smallSpacing }
        spacing: Kirigami.Units.smallSpacing
        opacity: button.minimized ? 0.5 : 1

        Kirigami.Icon {
            id: icon
            anchors.verticalCenter: parent.verticalCenter
            width: Kirigami.Units.iconSizes.medium
            height: width
            source: button.model.decoration
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - icon.width - parent.spacing
            visible: width > Kirigami.Units.gridUnit
            text: button.model.display
            elide: Text.ElideRight
            font: Kirigami.Theme.defaultFont
            color: Kirigami.Theme.textColor
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouseEvent => {
            if (mouseEvent.button === Qt.RightButton) {
                menu.popup()
            } else if (button.active) {
                button.tasksModel.requestToggleMinimized(button.modelIndex())
            } else {
                button.tasksModel.requestActivate(button.modelIndex())
            }
        }
    }

    QQC2.Menu {
        id: menu
        QQC2.MenuItem {
            text: i18nc("@action:inmenu", "Close")
            icon.name: "window-close"
            enabled: button.model.IsClosable === true
            onTriggered: button.tasksModel.requestClose(button.modelIndex())
        }
    }
}
