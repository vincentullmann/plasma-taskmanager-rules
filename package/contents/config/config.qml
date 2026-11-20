import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18nc("@title", "General")
        icon: "preferences-desktop"
        source: "ConfigGeneral.qml"
    }
    ConfigCategory {
        name: i18nc("@title", "Rules")
        icon: "preferences-desktop-color"
        source: "ConfigRules.qml"
    }
}
