import QtQml
import com.github.vincentullmann.taskmanagerrules.io
import "../../../package/contents/ui"
import "../../../package/contents/code/editor.js" as Editor

// Integration test of the rule editor page: edit the draft, validation errors, save to the shared file.
QtObject {
    id: root

    property var io: IoHelper {}
    readonly property string file: "~/.config/plasma-taskmanager-rules/rules.json"
    property var page: ConfigRules {}

    function fail(msg) { console.error("FAIL: " + msg); Qt.exit(1) }

    Component.onCompleted: {
        const p = page
        if (p.draft.rules.length !== 0) return fail("expected empty draft")

        p.edit(Editor.addRule(p.draft))
        if (p.draft.rules.length !== 1) return fail("addRule")
        if (p.draftErrors.length !== 0) return fail("fresh rule should be valid: " + p.draftErrors)

        p.edit(Editor.setCondition(p.draft, 0, "appId", { type: "regex", value: "(", caseSensitive: false }))
        if (p.draftErrors.length !== 1 || p.draftErrors[0].indexOf("not a valid regular expression") < 0)
            return fail("invalid regex should be reported: " + p.draftErrors)

        p.saveConfig()
        if (p.saveError === "") return fail("saving an invalid draft must fail")
        if (io.readFile(file).indexOf("(") >= 0) return fail("invalid draft reached the file")

        p.edit(Editor.setCondition(p.draft, 0, "appId", { type: "glob", value: "*slack*", caseSensitive: false }))
        p.edit(Editor.setAction(p.draft, 0, "fontColor", "#ff8800"))
        p.edit(Editor.setAction(p.draft, 0, "background", "#33ff8800"))
        p.edit(Editor.addRule(p.draft))
        p.edit(Editor.moveRule(p.draft, 1, -1))
        p.saveConfig()
        if (p.saveError !== "") return fail("valid save failed: " + p.saveError)

        const saved = JSON.parse(io.readFile(file))
        if (saved.rules.length !== 2) return fail("saved rule count")
        if (saved.rules[1].conditions.appId.glob !== "*slack*") return fail("rule order not saved")
        if (saved.rules[1].actions.background !== "#33ff8800") return fail("actions not saved")
        console.log("PASS")
        Qt.exit(0)
    }
}
