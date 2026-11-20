import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami
import org.kde.iconthemes as KIconThemes
import "../code/editor.js" as Editor

// One rule: enable toggle, name, reorder/delete, conditions, actions.
// Text fields commit on editingFinished so the card is not rebuilt while typing.
Kirigami.AbstractCard {
    id: card

    required property var rule
    required property int ruleIndex
    required property int ruleCount
    required property var draft

    signal edited(var newDraft)

    function localPath(url) {
        return decodeURIComponent(url.toString().replace(/^file:\/\//, ""))
    }

    contentItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            QQC2.CheckBox {
                checked: card.rule.enabled !== false
                QQC2.ToolTip.text: i18n("Enabled")
                QQC2.ToolTip.visible: hovered
                onToggled: card.edited(Editor.setRuleProp(card.draft, card.ruleIndex, "enabled", checked))
            }
            QQC2.TextField {
                Layout.fillWidth: true
                text: card.rule.name || ""
                placeholderText: i18n("Rule name")
                onEditingFinished: if (text !== card.rule.name) card.edited(Editor.setRuleProp(card.draft, card.ruleIndex, "name", text))
            }
            QQC2.ToolButton {
                icon.name: "go-up"
                enabled: card.ruleIndex > 0
                QQC2.ToolTip.text: i18n("Move up (lower priority)")
                QQC2.ToolTip.visible: hovered
                onClicked: card.edited(Editor.moveRule(card.draft, card.ruleIndex, -1))
            }
            QQC2.ToolButton {
                icon.name: "go-down"
                enabled: card.ruleIndex < card.ruleCount - 1
                QQC2.ToolTip.text: i18n("Move down (higher priority)")
                QQC2.ToolTip.visible: hovered
                onClicked: card.edited(Editor.moveRule(card.draft, card.ruleIndex, 1))
            }
            QQC2.ToolButton {
                icon.name: "edit-delete"
                QQC2.ToolTip.text: i18n("Delete rule")
                QQC2.ToolTip.visible: hovered
                onClicked: card.edited(Editor.removeRule(card.draft, card.ruleIndex))
            }
        }

        Kirigami.Heading { level: 5; text: i18n("When all of these match") }

        Repeater {
            model: Editor.conditionList(card.rule)
            delegate: ColumnLayout {
                id: cond
                required property var modelData
                Layout.fillWidth: true
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    QQC2.ComboBox {
                        model: Editor.FIELDS
                        currentIndex: Editor.FIELDS.indexOf(cond.modelData.field)
                        onActivated: index => card.edited(Editor.changeConditionField(card.draft, card.ruleIndex, cond.modelData.field, Editor.FIELDS[index]))
                    }
                    QQC2.ComboBox {
                        id: typeBox
                        model: Editor.TYPES
                        currentIndex: Editor.TYPES.indexOf(cond.modelData.type)
                        onActivated: index => card.edited(Editor.setCondition(card.draft, card.ruleIndex, cond.modelData.field,
                            { type: Editor.TYPES[index], value: valueField.text, caseSensitive: caseBox.checked }))
                    }
                    QQC2.TextField {
                        id: valueField
                        Layout.fillWidth: true
                        text: cond.modelData.value
                        placeholderText: i18n("Value")
                        onEditingFinished: card.edited(Editor.setCondition(card.draft, card.ruleIndex, cond.modelData.field,
                            { type: cond.modelData.type, value: text, caseSensitive: caseBox.checked }))
                    }
                    QQC2.CheckBox {
                        id: caseBox
                        text: i18n("Case sensitive")
                        checked: cond.modelData.caseSensitive
                        onToggled: card.edited(Editor.setCondition(card.draft, card.ruleIndex, cond.modelData.field,
                            { type: cond.modelData.type, value: valueField.text, caseSensitive: checked }))
                    }
                    QQC2.ToolButton {
                        icon.name: "list-remove"
                        enabled: Editor.conditionList(card.rule).length > 1
                        QQC2.ToolTip.text: i18n("Remove condition")
                        QQC2.ToolTip.visible: hovered
                        onClicked: card.edited(Editor.removeCondition(card.draft, card.ruleIndex, cond.modelData.field))
                    }
                }
                QQC2.Label {
                    // Live while typing, before the value is committed to the draft.
                    readonly property string err: Editor.conditionError({ type: cond.modelData.type, value: valueField.text })
                    visible: err !== ""
                    text: i18n("Invalid regular expression: %1", err)
                    color: Kirigami.Theme.negativeTextColor
                }
            }
        }

        QQC2.Button {
            icon.name: "list-add"
            text: i18nc("@action:button", "Add Condition")
            enabled: Editor.conditionList(card.rule).length < Editor.FIELDS.length
            onClicked: card.edited(Editor.addCondition(card.draft, card.ruleIndex))
        }

        Kirigami.Heading { level: 5; text: i18n("Then apply") }

        GridLayout {
            Layout.fillWidth: true
            columns: 2

            QQC2.Label { text: i18n("Icon") }
            RowLayout {
                Layout.fillWidth: true
                Kirigami.Icon {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                    visible: iconField.text !== ""
                    source: iconField.text.charAt(0) === "/" ? "file://" + encodeURI(iconField.text)
                          : iconField.text.indexOf("~/") === 0 ? "" : iconField.text
                }
                QQC2.TextField {
                    id: iconField
                    Layout.fillWidth: true
                    text: card.rule.actions.icon || ""
                    placeholderText: i18n("Theme icon name, or a file path starting with / or ~")
                    onEditingFinished: card.edited(Editor.setAction(card.draft, card.ruleIndex, "icon", text))
                }
                QQC2.Button {
                    text: i18nc("@action:button", "Theme…")
                    onClicked: themeDialog.open()
                }
                QQC2.Button {
                    text: i18nc("@action:button", "File…")
                    onClicked: iconFileDialog.open()
                }
                QQC2.ToolButton {
                    icon.name: "edit-clear"
                    enabled: iconField.text !== ""
                    onClicked: card.edited(Editor.setAction(card.draft, card.ruleIndex, "icon", ""))
                }
            }

            QQC2.Label { text: i18n("Font color") }
            ColorRow {
                key: "fontColor"
                alpha: false
            }

            QQC2.Label { text: i18n("Background") }
            ColorRow {
                key: "background"
                alpha: true
            }
        }
    }

    KIconThemes.IconDialog {
        id: themeDialog
        onIconNameChanged: iconName => {
            if (iconName !== "") card.edited(Editor.setAction(card.draft, card.ruleIndex, "icon", iconName))
        }
    }

    FileDialog {
        id: iconFileDialog
        nameFilters: [i18n("Images (*.svg *.svgz *.png *.xpm *.jpg)"), i18n("All files (*)")]
        onAccepted: card.edited(Editor.setAction(card.draft, card.ruleIndex, "icon", card.localPath(selectedFile)))
    }

    // Text field with a swatch that opens a color dialog. Qt color strings are #AARRGGBB when
    // translucent, #RRGGBB otherwise, which is exactly what the rules accept.
    component ColorRow: RowLayout {
        id: colorRow
        required property string key
        required property bool alpha
        readonly property string current: card.rule.actions[key] || ""

        Layout.fillWidth: true

        Rectangle {
            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
            Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
            border.color: Kirigami.Theme.disabledTextColor
            color: colorRow.current !== "" && Editor.colorError(colorRow.current) === "" ? colorRow.current : "transparent"
        }
        QQC2.TextField {
            id: colorField
            Layout.fillWidth: true
            text: colorRow.current
            placeholderText: colorRow.alpha ? "#AARRGGBB" : "#RRGGBB"
            onEditingFinished: if (Editor.colorError(text) === "") card.edited(Editor.setAction(card.draft, card.ruleIndex, colorRow.key, text))
        }
        QQC2.Label {
            readonly property string err: Editor.colorError(colorField.text)
            visible: err !== ""
            text: err
            color: Kirigami.Theme.negativeTextColor
        }
        QQC2.Button {
            text: i18nc("@action:button", "Pick…")
            onClicked: dialog.open()
        }
        QQC2.ToolButton {
            icon.name: "edit-clear"
            enabled: colorRow.current !== ""
            onClicked: card.edited(Editor.setAction(card.draft, card.ruleIndex, colorRow.key, ""))
        }
        ColorDialog {
            id: dialog
            options: colorRow.alpha ? ColorDialog.ShowAlphaChannel : 0
            selectedColor: colorRow.current !== "" && Editor.colorError(colorRow.current) === "" ? colorRow.current : "white"
            onAccepted: card.edited(Editor.setAction(card.draft, card.ruleIndex, colorRow.key, selectedColor.toString()))
        }
    }
}
