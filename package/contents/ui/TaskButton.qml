import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

// One window. Roles come from TaskManager.TasksModel.
Item {
    id: button

    required property var tasksModel
    required property var store
    required property int index
    required property var model

    readonly property bool active: model.IsActive === true
    readonly property bool minimized: model.IsMinimized === true
    readonly property bool attention: model.IsDemandingAttention === true

    // Rule actions for this window. Re-evaluates when the title, app, pid, or the rule config changes.
    readonly property var ruleActions: store.evaluate({
        title: model.display,
        appId: model.AppId,
        name: model.AppName,
        exe: store.exePath(model.AppPid)
    })
    readonly property string iconSource: ruleActions.icon ? store.iconSource(ruleActions.icon) : ""
    readonly property color labelColor: ruleActions.fontColor !== undefined ? ruleActions.fontColor : Kirigami.Theme.textColor

    function modelIndex() {
        return tasksModel.makeModelIndex(index)
    }

    // Rule `background`: fills the whole button, alpha included. Under the state overlay.
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Kirigami.Units.cornerRadius
        visible: button.ruleActions.background !== undefined
        color: button.ruleActions.background !== undefined ? button.ruleActions.background : "transparent"
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
            source: button.iconSource !== "" ? button.iconSource : button.model.decoration
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - icon.width - parent.spacing
            visible: width > Kirigami.Units.gridUnit
            text: button.model.display
            elide: Text.ElideRight
            font: Kirigami.Theme.defaultFont
            color: button.labelColor
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
