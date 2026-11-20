import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.taskmanager as TaskManager
import com.github.vincentullmann.taskmanagerrules.io

PlasmoidItem {
    id: root

    // No compact/popup form: the task list always fills the panel slot.
    preferredRepresentation: fullRepresentation

    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    ConfigStore {
        id: rulesStore
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
        vertical: root.vertical
        iconSize: Plasmoid.configuration.iconSize
        fontSize: Plasmoid.configuration.fontSize
        borderRadius: Plasmoid.configuration.borderRadius
        backgroundColor: Plasmoid.configuration.backgroundColor
        padding: Plasmoid.configuration.padding
        gap: Plasmoid.configuration.gap
    }
}
