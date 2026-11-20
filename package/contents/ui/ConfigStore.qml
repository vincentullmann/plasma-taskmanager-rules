import QtQml
import com.github.vincentullmann.taskmanagerrules.io
import "../code/rules.js" as Rules

// Shared rules file -> compiled engine. One per TM instance; every instance watches the same file.
QtObject {
    id: store

    property string path: "~/.config/plasma-taskmanager-rules/rules.json"

    // Last good state. A bad file never replaces it; `error` explains what is wrong.
    property var state: Rules.initialState()
    readonly property var config: state.config
    readonly property var engine: state.engine
    readonly property string error: state.error

    readonly property string home: io.expandPath("~")

    // Bumps on every successful or failed reload so bindings re-evaluate.
    property int revision: 0

    function reload() {
        if (!io.exists(path)) {
            io.writeFile(path, Rules.serialize(Rules.defaultConfig()))
        }
        state = Rules.applyText(state, io.readFile(path), { home: home })
        revision++
    }

    // Validates, then writes the shared file. Returns "" on success, else the error text.
    function save(newConfig) {
        const v = Rules.validate(newConfig)
        if (!v.ok) return v.errors.join("\n")
        if (!io.writeFile(path, Rules.serialize(newConfig))) return "could not write " + path
        reload()
        return ""
    }

    function evaluate(window) {
        return Rules.evaluate(engine, window)
    }

    property IoHelper io: IoHelper {
        onFileChanged: store.reload()
    }

    Component.onCompleted: {
        reload()      // creates the default file (and its directory) first
        io.watch(path)
    }
}
