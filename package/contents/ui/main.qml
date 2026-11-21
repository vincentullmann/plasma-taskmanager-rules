import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.taskmanager as TaskManager
import com.github.vincentullmann.taskmanagerrules.io

PlasmoidItem {
    id: root

    // No compact/popup form: the task list always fills the panel slot.
    preferredRepresentation: fullRepresentation

    // Like the stock task manager: ignore the panel's applet margins and fill the full panel thickness.
    Plasmoid.constraintHints: Plasmoid.CanFillArea

    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    ConfigStore {
        id: rulesStore
    }

    // "Apply to all instances" in the config dialog writes this file; every instance copies it into its own config.
    property real lastAppearanceStamp: 0
    function readAppearance() {
        const text = appearanceIo.readFile(appearancePath)
        if (!text) return null
        try { return JSON.parse(text) } catch (e) { return null }
    }
    readonly property string appearancePath: "~/.config/plasma-taskmanager-rules/appearance.json"
    IoHelper {
        id: appearanceIo
        onFileChanged: {
            const msg = root.readAppearance()
            if (!msg || !msg.settings || msg.stamp === root.lastAppearanceStamp) return
            root.lastAppearanceStamp = msg.stamp
            const cfg = Plasmoid.configuration
            for (const k of ["iconSize", "fontSize", "borderRadius", "backgroundColor", "padding", "gap", "iconGap"]) {
                if (msg.settings[k] !== undefined && cfg[k] !== msg.settings[k]) cfg[k] = msg.settings[k]
            }
        }
    }
    Component.onCompleted: {
        // Remember what is already there so only later clicks apply.
        const msg = readAppearance()
        if (msg) lastAppearanceStamp = msg.stamp
        appearanceIo.watch(appearancePath)
    }

    AudioStreams { id: audioStreams }
    LauncherProgress { id: launcherProgress }

    TaskManager.VirtualDesktopInfo { id: virtualDesktopInfo }
    TaskManager.ActivityInfo { id: activityInfo }

    TaskManager.TasksModel {
        id: windowsModel

        // Only this panel's screen, the current virtual desktop and activity.
        filterByScreen: true
        filterByVirtualDesktop: true
        filterByActivity: true
        screenGeometry: Plasmoid.containment.screenGeometry
        virtualDesktop: virtualDesktopInfo.currentDesktop
        activity: activityInfo.currentActivity

        // Light: no grouping. Pinned launchers are per panel and merge with their running windows.
        groupMode: TaskManager.TasksModel.GroupDisabled
        sortMode: TaskManager.TasksModel.SortManual
        separateLaunchers: false
        launcherList: Plasmoid.configuration.launchers
    }

    // Persist pin / unpin done through the context menu.
    Connections {
        target: windowsModel
        function onLauncherListChanged() {
            if (windowsModel.launcherList.join("\n") !== Plasmoid.configuration.launchers.join("\n"))
                Plasmoid.configuration.launchers = windowsModel.launcherList
        }
    }

    fullRepresentation: TaskList {
        store: rulesStore
        tasksModel: windowsModel
        audio: audioStreams
        progress: launcherProgress
        onRuleRequested: Plasmoid.internalAction("configure").trigger()
        vertical: root.vertical
        location: Plasmoid.location
        iconSize: Plasmoid.configuration.iconSize
        fontSize: Plasmoid.configuration.fontSize
        borderRadius: Plasmoid.configuration.borderRadius
        backgroundColor: Plasmoid.configuration.backgroundColor
        padding: Plasmoid.configuration.padding
        gap: Plasmoid.configuration.gap
        iconGap: Plasmoid.configuration.iconGap
    }
}
