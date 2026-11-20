import QtQml
import com.github.vincentullmann.taskmanagerrules.io
import "../../../package/contents/ui"

// Headless smoke test of ConfigStore: default creation, live reload, last-good fallback.
// Run: QT_QPA_PLATFORM=offscreen qml6 -I <build dir> tst_configstore.qml   (exit 0 = pass)
QtObject {
    id: root

    readonly property string file: "/tmp/tmr-test-" + Date.now() + "/rules.json"
    readonly property string oneRule: JSON.stringify({ version: 1, rules: [
        { name: "a", enabled: true, conditions: { appId: { exact: "x" } }, actions: { fontColor: "#ff0000" } }] })
    readonly property string twoRules: JSON.stringify({ version: 1, rules: [
        { name: "a", enabled: true, conditions: { appId: { exact: "x" } }, actions: { fontColor: "#ff0000" } },
        { name: "b", enabled: true, conditions: { appId: { exact: "y" } }, actions: { fontColor: "#00ff00" } }] })

    property var writer: IoHelper {}
    property var store: ConfigStore { path: root.file }

    property int step: 0
    property int ticks: 0

    function fail(msg) { console.error("FAIL step " + step + ": " + msg); Qt.exit(1) }
    function advance() { step++; ticks = 0 }

    property var timer: Timer {
        interval: 100; repeat: true; running: true
        onTriggered: {
            root.ticks++
            if (root.ticks > 40) return root.fail("timeout")
            switch (root.step) {
            case 0:
                if (!root.writer.exists(root.file)) return root.fail("default file not created")
                if (store.error !== "" || store.config.rules.length !== 0) return root.fail("bad initial state")
                root.writer.writeFile(root.file, root.oneRule); root.advance(); break
            case 1:
                if (store.config.rules.length === 1) {
                    root.writer.writeFile(root.file, "{ not json"); root.advance()
                }
                break
            case 2:
                if (store.error !== "") {
                    if (store.config.rules.length !== 1) return root.fail("last good rules lost")
                    if (store.evaluate({ appId: "x" }).fontColor !== "#ff0000") return root.fail("engine lost")
                    root.writer.writeFile(root.file, root.twoRules); root.advance()
                }
                break
            case 3:
                if (store.config.rules.length === 2) {
                    if (store.error !== "") return root.fail("error not cleared")
                    var e = store.save({ version: 1, rules: [{ name: "r", conditions: {}, actions: {} }] })
                    if (e === "") return root.fail("invalid save accepted")
                    if (store.save({ version: 1, rules: [] }) !== "") return root.fail("valid save rejected")
                    if (store.config.rules.length !== 0) return root.fail("save did not reload")
                    console.log("PASS"); Qt.exit(0)
                }
                break
            }
        }
    }
}
