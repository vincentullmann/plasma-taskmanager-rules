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
    property int location: 0              // Plasmoid.location (0 = floating)
    property bool tooltips: true          // off in headless tests (Plasma tooltips open real windows)
    readonly property bool menuOpen: menu.visible
    signal dragFinished(real translation)
    signal ruleRequested()                // "Add rule" / "Edit rule": the config dialog should open

    // Live drag. Positions are pointer coordinates along the list axis, in the list's content item
    // (stable even though this delegate moves while it is dragged).
    property real cellSize: 0             // one slot along the axis, gap included
    property int count: 0
    signal moveRequested(int target)      // the dragged centre crossed into another slot

    property bool dragging: false
    property bool wasDragged: false       // the release that ends a drag must not count as a click
    property bool dragArmed: false
    property real dragStart: 0            // pointer position at press
    property real dragGrab: 0             // pointer offset inside the button at press
    readonly property real slot: vertical ? y : x
    property real dragPointer: 0
    // How far the content is shifted from its slot so that it sits under the pointer.
    readonly property real dragDelta: dragging ? dragPointer - dragGrab - slot : 0
    // What is drawn: follows dragDelta exactly while dragging, eases back to the slot on release.
    property real renderDelta: dragDelta
    property bool settling: false
    Behavior on renderDelta {
        enabled: button.settling
        NumberAnimation { duration: Kirigami.Units.shortDuration; onRunningChanged: if (!running) button.settling = false }
    }
    z: dragging ? 10 : 0
    // The whole button (background, badges, progress) follows the pointer, like a browser tab.
    transform: Translate {
        x: button.vertical ? 0 : button.renderDelta
        y: button.vertical ? button.renderDelta : 0
    }

    property int iconSize: Kirigami.Units.iconSizes.medium
    property int fontSize: 0
    property int borderRadius: Kirigami.Units.cornerRadius
    property color backgroundColor: "transparent"
    property int padding: Kirigami.Units.smallSpacing
    property int iconGap: Kirigami.Units.smallSpacing
    property real indicatorSaturation: 0.75   // multipliers applied to the base colour
    property real indicatorValue: 1.25
    property int indicatorHeight: 2       // bottom line on the active window; 0 = off
    readonly property font labelFont: {
        const f = Kirigami.Theme.defaultFont
        if (fontSize > 0) f.pointSize = fontSize
        return f
    }

    function beginDrag(pos) {
        settling = false
        dragStart = pos
        dragGrab = pos - slot
        dragArmed = true
        wasDragged = false
    }
    function moveDrag(pos) {
        if (!dragArmed) return
        if (!dragging && Math.abs(pos - dragStart) < Qt.styleHints.startDragDistance) return
        dragging = true
        dragPointer = pos
        const target = Tasks.dropIndex(dragPointer - dragGrab + cellSize / 2, cellSize, count)
        if (target !== index) moveRequested(target)
    }
    function endDrag() {
        dragArmed = false
        if (!dragging) return
        settling = true
        dragging = false
        wasDragged = true
    }

    readonly property bool active: model.IsActive === true
    readonly property bool minimized: model.IsMinimized === true
    readonly property bool attention: model.IsDemandingAttention === true
    readonly property bool launcher: model.IsLauncher === true      // pinned, not running
    readonly property bool pinned: model.HasLauncher === true || launcher
    readonly property int pid: model.AppPid > 0 ? model.AppPid : 0

    readonly property string tooltipText: model.display
    readonly property string tooltipLabel: model.AppName ? model.AppName : model.display
    readonly property string exePath: pid > 0 ? store.exePath(pid) : ""
    // Header is the label (app name); under it the title (light grey), then app id and exe (grey, small).
    readonly property string tooltipSubText: {
        const esc = s => String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
        const lines = []
        if (model.AppName && tooltipText) lines.push('<span style="color:#d0d0d0">' + esc(tooltipText) + '</span>')
        if (model.AppId) lines.push('<small style="color:#909090">app_id: ' + esc(model.AppId) + '</small>')
        if (exePath !== "") lines.push('<small style="color:#909090">exe: ' + esc(exePath) + '</small>')
        return lines.join("<br>")
    }
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

    readonly property var windowInfo: ({
        title: model.display, appId: model.AppId, name: model.AppName, exe: pid > 0 ? store.exePath(pid) : ""
    })
    // Re-evaluates when the rules change (ruleIndexFor reads store.config), like ruleActions.
    readonly property bool hasRule: store.ruleIndexFor(windowInfo) >= 0

    // Creates a matching rule first when there is none, then asks for the config dialog.
    function addOrEditRule() {
        if (!hasRule) store.addRuleFor(windowInfo)
        ruleRequested()
    }

    function modelIndex() {
        return tasksModel.makeModelIndex(index)
    }

    // Default background from the General settings.
    Rectangle {
        anchors { fill: parent; leftMargin: 1; rightMargin: 1 }
        radius: button.borderRadius
        color: button.backgroundColor
    }

    // Rule `background`: fills the whole button, alpha included. Under the state overlay.
    Rectangle {
        anchors { fill: parent; leftMargin: 1; rightMargin: 1 }
        radius: button.borderRadius
        visible: button.ruleActions.background !== undefined
        color: button.ruleActions.background !== undefined ? button.ruleActions.background : "transparent"
    }

    Rectangle {
        id: background
        anchors { fill: parent; leftMargin: 1; rightMargin: 1 }
        radius: button.borderRadius
        color: button.attention ? Kirigami.Theme.neutralTextColor
             : button.active ? Kirigami.Theme.highlightColor
             : Kirigami.Theme.textColor
        opacity: button.attention ? (hover.hovered ? 0.45 : 0.35)
               : button.active ? (hover.hovered ? 0.40 : 0.30)
               : hover.hovered ? 0.15
               : 0
        Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }
    }

    // Hover highlight via a handler: the tooltip area above the mouse area swallows hover events.
    HoverHandler { id: hover }

    // Active-window marker: the rule background (else the default background) with saturation and
    // value scaled by the General settings multipliers, opaque.
    readonly property color indicatorBase: ruleActions.background !== undefined ? ruleActions.background : backgroundColor
    readonly property color indicatorColor: {
        // Rule colours are strings; a typed `color` property converts them so hsv* work.
        const base = indicatorBase
        return Qt.hsva(Math.max(0, base.hsvHue),
                       Math.min(1, base.hsvSaturation * indicatorSaturation),
                       Math.min(1, base.hsvValue * indicatorValue), 1)
    }
    Rectangle {
        objectName: "indicator"
        visible: button.indicatorHeight > 0 && button.active
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 1; rightMargin: 1 }
        height: button.indicatorHeight
        color: button.indicatorColor
    }

    Row {
        anchors { fill: parent; leftMargin: button.padding; rightMargin: button.padding }
        spacing: button.iconGap
        opacity: (button.minimized || button.launcher) ? 0.5 : 1

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
        anchors { left: parent.left; bottom: parent.bottom; leftMargin: 1 }
        width: (parent.width - 2) * Math.max(0, button.progressValue)
        height: 3
        color: Kirigami.Theme.highlightColor
    }


    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        preventStealing: true
        function listPos(m) {
            const p = mouse.mapToItem(button.parent, m.x, m.y)
            return button.vertical ? p.y : p.x
        }
        onPressed: mouseEvent => {
            if (mouseEvent.button === Qt.LeftButton) button.beginDrag(listPos(mouseEvent))
        }
        onPositionChanged: mouseEvent => button.moveDrag(listPos(mouseEvent))
        onReleased: button.endDrag()
        onCanceled: button.endDrag()
        onClicked: mouseEvent => {
            if (button.wasDragged) return
            if (mouseEvent.button === Qt.RightButton) menu.popup(button, mouseEvent.x, mouseEvent.y)
            else button.activate()
        }
    }

    // Plasma's own tooltip: a real tooltip window that never sits under the pointer, so it doesn't flicker.
    Loader {
        anchors.fill: parent
        active: button.tooltips
        source: "TaskToolTip.qml"
        onLoaded: item.button = button
    }

    // A real popup window: not clipped to the panel, positioned by the compositor, no panel-sized scrollbar.
    QQC2.Menu {
        id: menu
        popupType: QQC2.Popup.Window
        QQC2.MenuItem {
            text: button.pinned ? i18nc("@action:inmenu", "Unpin") : i18nc("@action:inmenu", "Pin")
            icon.name: button.pinned ? "window-unpin" : "window-pin"
            onTriggered: button.togglePin()
        }
        QQC2.MenuItem {
            text: button.hasRule ? i18nc("@action:inmenu", "Edit Rule…") : i18nc("@action:inmenu", "Add Rule…")
            icon.name: button.hasRule ? "document-edit" : "list-add"
            onTriggered: button.addOrEditRule()
        }
        QQC2.MenuSeparator {}
        QQC2.MenuItem {
            text: i18nc("@action:inmenu", "Close")
            icon.name: "window-close"
            enabled: !button.launcher && button.model.IsClosable === true
            onTriggered: button.tasksModel.requestClose(button.modelIndex())
        }
    }
}
