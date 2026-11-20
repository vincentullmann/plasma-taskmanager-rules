import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import "../code/tasks.js" as Tasks

// One window. Roles come from TaskManager.TasksModel.
Item {
    id: button

    required property var tasksModel
    required property var store
    required property int index
    required property var model

    // Optional collaborators (null when unavailable): audio.state(pid) / audio.setMuted(pid, bool),
    // progress.progress(desktopId) -> {visible, value}.
    property var audio: null
    property var progress: null

    // Emitted when a drag ends; `translation` is how far the button was dragged along the list axis.
    property bool vertical: false
    signal dragFinished(real translation)

    property int iconSize: Kirigami.Units.iconSizes.medium
    property int fontSize: 0
    property int borderRadius: Kirigami.Units.cornerRadius
    property color backgroundColor: "transparent"
    property int padding: Kirigami.Units.smallSpacing
    readonly property font labelFont: {
        const f = Kirigami.Theme.defaultFont
        if (fontSize > 0) f.pointSize = fontSize
        return f
    }

    readonly property bool active: model.IsActive === true
    readonly property bool minimized: model.IsMinimized === true
    readonly property bool attention: model.IsDemandingAttention === true
    readonly property bool launcher: model.IsLauncher === true      // pinned, not running
    readonly property bool pinned: model.HasLauncher === true || launcher
    readonly property int pid: model.AppPid > 0 ? model.AppPid : 0

    readonly property string tooltipText: model.display
    readonly property var audioBadge: Tasks.audioBadge(audio ? audio.state(pid) : { hasAudio: false })
    readonly property real progressValue: {
        if (!progress) return -1
        progress.revision       // re-evaluate when the helper reports an update
        const id = model.StorageId ? model.StorageId : (model.AppId ? model.AppId + ".desktop" : "")
        return Tasks.progressFraction(id !== "" ? progress.progress(id) : undefined)
    }

    function toggleMute() {
        if (audio) audio.setMuted(pid, !audioBadge.muted)
    }

    function activate() {
        if (launcher) tasksModel.requestNewInstance(modelIndex())
        else if (active) tasksModel.requestToggleMinimized(modelIndex())
        else tasksModel.requestActivate(modelIndex())
    }

    function togglePin() {
        if (pinned) tasksModel.requestRemoveLauncher(model.LauncherUrlWithoutIcon)
        else if (model.LauncherUrlWithoutIcon) tasksModel.requestAddLauncher(model.LauncherUrlWithoutIcon)
    }

    // Rule actions for this window. Re-evaluates when the title, app, pid, or the rule config changes.
    readonly property var ruleActions: store.evaluate({
        title: model.display,
        appId: model.AppId,
        name: model.AppName,
        exe: pid > 0 ? store.exePath(pid) : ""
    })
    readonly property string iconSource: ruleActions.icon ? store.iconSource(ruleActions.icon) : ""
    readonly property color labelColor: ruleActions.fontColor !== undefined ? ruleActions.fontColor : Kirigami.Theme.textColor

    function modelIndex() {
        return tasksModel.makeModelIndex(index)
    }

    // Default background from the General settings.
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: button.borderRadius
        color: button.backgroundColor
    }

    // Rule `background`: fills the whole button, alpha included. Under the state overlay.
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: button.borderRadius
        visible: button.ruleActions.background !== undefined
        color: button.ruleActions.background !== undefined ? button.ruleActions.background : "transparent"
    }

    Rectangle {
        id: background
        anchors.fill: parent
        anchors.margins: 1
        radius: button.borderRadius
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
        anchors { fill: parent; leftMargin: button.padding; rightMargin: button.padding }
        spacing: button.padding
        opacity: (button.minimized || button.launcher) ? 0.5 : 1
        transform: Translate {
            x: button.vertical ? 0 : drag.translation.x
            y: button.vertical ? drag.translation.y : 0
        }

        Kirigami.Icon {
            id: icon
            anchors.verticalCenter: parent.verticalCenter
            width: button.iconSize
            height: width
            source: button.iconSource !== "" ? button.iconSource : button.model.decoration
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - icon.width - parent.spacing
            visible: width > Kirigami.Units.gridUnit
            text: button.model.display
            elide: Text.ElideRight
            font: button.labelFont
            color: button.labelColor
        }
    }

    // Audio badge: shown while playing or muted; click toggles mute.
    Kirigami.Icon {
        id: audioIcon
        objectName: "audioBadge"
        z: 1                    // above the full-size click area
        visible: button.audioBadge.visible
        anchors { right: parent.right; rightMargin: button.padding; verticalCenter: parent.verticalCenter }
        width: Math.min(button.iconSize, Kirigami.Units.iconSizes.small)
        height: width
        source: button.audioBadge.icon

        MouseArea {
            anchors.fill: parent
            anchors.margins: -2
            onClicked: button.toggleMute()
        }
    }

    // Progress bar (downloads and other jobs).
    Rectangle {
        visible: button.progressValue >= 0
        anchors { left: parent.left; bottom: parent.bottom; margins: 1 }
        width: (parent.width - 2) * Math.max(0, button.progressValue)
        height: 3
        color: Kirigami.Theme.highlightColor
    }

    DragHandler {
        id: drag
        target: null
        xAxis.enabled: !button.vertical
        yAxis.enabled: button.vertical
        onActiveChanged: if (!active) button.dragFinished(button.vertical ? translation.y : translation.x)
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouseEvent => {
            if (mouseEvent.button === Qt.RightButton) menu.popup()
            else button.activate()
        }
    }

    QQC2.ToolTip {
        visible: mouse.containsMouse && !drag.active && !menu.visible
        delay: Kirigami.Units.toolTipDelay
        text: button.tooltipText
    }

    QQC2.Menu {
        id: menu
        QQC2.MenuItem {
            text: button.pinned ? i18nc("@action:inmenu", "Unpin") : i18nc("@action:inmenu", "Pin")
            icon.name: button.pinned ? "window-unpin" : "window-pin"
            onTriggered: button.togglePin()
        }
        QQC2.MenuItem {
            text: i18nc("@action:inmenu", "Close")
            icon.name: "window-close"
            enabled: !button.launcher && button.model.IsClosable === true
            onTriggered: button.tasksModel.requestClose(button.modelIndex())
        }
    }
}
