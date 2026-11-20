import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.taskmanager as TaskManager

PlasmoidItem {
    id: root

    // No compact/popup form: the task list always fills the panel slot.
    preferredRepresentation: fullRepresentation

    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    ConfigStore {
        id: store
    }

    TaskManager.VirtualDesktopInfo { id: virtualDesktopInfo }
    TaskManager.ActivityInfo { id: activityInfo }

    TaskManager.TasksModel {
        id: tasksModel

        // Only this panel's screen, the current virtual desktop and activity.
        filterByScreen: true
        filterByVirtualDesktop: true
        filterByActivity: true
        screenGeometry: Plasmoid.containment.screenGeometry
        virtualDesktop: virtualDesktopInfo.currentDesktop
        activity: activityInfo.currentActivity

        // Light: no launchers, no grouping.
        groupMode: TaskManager.TasksModel.GroupDisabled
        sortMode: TaskManager.TasksModel.SortManual
        separateLaunchers: false
    }

    fullRepresentation: TaskList {
        store: store
        tasksModel: tasksModel
        vertical: root.vertical
    }
}
