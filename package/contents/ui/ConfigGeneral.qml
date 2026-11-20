import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

// Appearance settings, stored per widget instance in the plasmoid config.
KCM.SimpleKCM {
    id: page

    property alias cfg_iconSize: iconSize.value
    property alias cfg_fontSize: fontSize.value
    property alias cfg_borderRadius: borderRadius.value
    property alias cfg_padding: padding.value
    property alias cfg_gap: gap.value
    property int cfg_iconSizeDefault
    property int cfg_fontSizeDefault
    property int cfg_borderRadiusDefault
    property int cfg_paddingDefault
    property int cfg_gapDefault

    Kirigami.FormLayout {
        QQC2.SpinBox {
            id: iconSize
            Kirigami.FormData.label: i18n("Icon size:")
            from: 8; to: 128
            textFromValue: (v) => i18n("%1 px", v)
        }
        QQC2.SpinBox {
            id: fontSize
            Kirigami.FormData.label: i18n("Font size:")
            from: 0; to: 72
            textFromValue: (v) => v === 0 ? i18n("System default") : i18n("%1 pt", v)
        }
        QQC2.SpinBox {
            id: borderRadius
            Kirigami.FormData.label: i18n("Border radius:")
            from: 0; to: 64
            textFromValue: (v) => i18n("%1 px", v)
        }
        QQC2.SpinBox {
            id: padding
            Kirigami.FormData.label: i18n("Padding:")
            from: 0; to: 64
            textFromValue: (v) => i18n("%1 px", v)
        }
        QQC2.SpinBox {
            id: gap
            Kirigami.FormData.label: i18n("Gap between windows:")
            from: 0; to: 64
            textFromValue: (v) => i18n("%1 px", v)
        }
    }
}
