import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import "../code/editor.js" as Editor
import "../code/rules.js" as Rules

// Rule editor. Edits a draft copy of the shared rules file; Apply/OK writes the file, and every
// task manager instance picks the change up through its file watch.
KCM.SimpleKCM {
    id: page

    // Plasma enables Apply when this fires.
    signal configurationChanged()

    ConfigStore { id: store }

    property var draft: store.config
    property string saveError: ""
    readonly property var draftErrors: Rules.validate(draft).errors

    function edit(newDraft) {
        // Drafts arriving through a QML signal(var) hold V4Sequence instead of real arrays; a JSON
        // round trip restores plain arrays (Rules.validate relies on Array.isArray).
        draft = JSON.parse(JSON.stringify(newDraft))
        saveError = ""
        configurationChanged()
    }

    // Called by the config dialog on Apply / OK.
    function saveConfig() {
        page.forceActiveFocus()   // commits a text field that is still being edited
        saveError = store.save(draft)
    }

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: store.error !== ""
            type: Kirigami.MessageType.Warning
            text: i18n("The rules file on disk is invalid. The last good rules stay in effect.\n%1", store.error)
        }
        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: page.draftErrors.length > 0
            type: Kirigami.MessageType.Error
            text: i18n("These rules cannot be saved yet:\n%1", page.draftErrors.join("\n"))
        }
        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: page.saveError !== ""
            type: Kirigami.MessageType.Error
            text: page.saveError
        }

        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            opacity: 0.7
            text: i18n("Every matching rule applies, top to bottom. A later rule overrides an earlier one, field by field. All conditions in a rule must match.")
        }

        Repeater {
            model: page.draft.rules
            delegate: RuleCard {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                rule: modelData
                ruleIndex: index
                ruleCount: page.draft.rules.length
                draft: page.draft
                onEdited: newDraft => page.edit(newDraft)
            }
        }

        QQC2.Button {
            icon.name: "list-add"
            text: i18nc("@action:button", "Add Rule")
            onClicked: page.edit(Editor.addRule(page.draft))
        }
    }
}
