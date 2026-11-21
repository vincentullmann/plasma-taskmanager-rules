import QtQuick
import "../../../package/contents/ui"

// Task button wiring: tooltip, audio badge + mute, progress, pinned launchers; drag drop target in the list.
Item {
    id: root
    width: 600; height: 40

    property var calls: []
    function fail(msg) { console.error("FAIL: " + msg); Qt.exit(1) }

    property var tasksModel: QtObject {
        function makeModelIndex(i) { return i }
        function requestActivate(i) { root.calls.push("activate") }
        function requestToggleMinimized(i) { root.calls.push("minimize") }
        function requestNewInstance(i) { root.calls.push("newInstance") }
        function requestAddLauncher(u) { root.calls.push("add:" + u) }
        function requestRemoveLauncher(u) { root.calls.push("remove:" + u) }
        function requestClose(i) { root.calls.push("close") }
    }
    property var store: QtObject {
        property var added: []
        function evaluate(w) { return ({}) }
        function ruleIndexFor(w) { return w.appId === "ruled" ? 0 : -1 }
        function addRuleFor(w) { added.push(w.appId); return "" }
        function exePath(pid) { return "" }
        function iconSource(i) { return i }
    }
    property var audio: QtObject {
        property var muted: ({})
        function state(pid) { return pid === 42 ? { hasAudio: true, playing: true, muted: muted[42] === true } : { hasAudio: false, playing: false, muted: false } }
        function setMuted(pid, m) { const x = Object.assign({}, muted); x[pid] = m; muted = x; root.calls.push("mute:" + pid + ":" + m) }
    }
    property var progress: QtObject {
        property int revision: 0
        property var box: ({ v: 0.4 })     // in-place changes notify nobody, like the C++ helper
        function progress(id) { return id === "dl.desktop" ? { visible: true, value: box.v } : { visible: false, value: 0 } }
    }

    Component {
        id: buttonComp
        TaskButton {
            property var roles
            model: roles
            index: 0
            tasksModel: root.tasksModel
            store: root.store
            audio: root.audio
            progress: root.progress
            tooltips: false
            width: 200; height: 30
        }
    }
    Component { id: listComp; TaskList { tasksModel: ListModel { ListElement { display: "a" } ListElement { display: "b" } ListElement { display: "c" } ListElement { display: "d" } } store: root.store; tooltips: false } }

    function make(roles) { return buttonComp.createObject(root, { roles: roles }) }

    Component.onCompleted: {
        // tooltip shows the full window title
        let b = make({ display: "Long window title - App", AppPid: 7, AppId: "app" })
        if (b.tooltipText !== "Long window title - App") return fail("tooltip text: " + b.tooltipText)

        // no audio badge for a silent window, no progress without a matching launcher
        if (b.audioBadge.visible) return fail("badge visible for silent window")
        if (b.progressValue !== -1) return fail("progress should be hidden: " + b.progressValue)

        // audio badge: shown while playing, click toggles mute
        b = make({ display: "player", AppPid: 42, AppId: "player" })
        if (!b.audioBadge.visible || b.audioBadge.icon !== "audio-volume-high") return fail("playing badge")
        b.toggleMute()
        if (calls.pop() !== "mute:42:true") return fail("first toggle should mute")
        if (b.audioBadge.icon !== "audio-volume-muted") return fail("badge should show muted")
        b.toggleMute()
        if (calls.pop() !== "mute:42:false") return fail("second toggle should unmute")

        // progress from the launcher entry matching the app's desktop file
        b = make({ display: "downloads", AppPid: 9, AppId: "dl" })
        if (Math.abs(b.progressValue - 0.4) > 1e-9) return fail("progress value: " + b.progressValue)

        // progress follows updates (the binding must depend on the helper's revision)
        progress.box.v = 0.9
        progress.revision++
        if (Math.abs(b.progressValue - 0.9) > 1e-9) return fail("progress did not update: " + b.progressValue)

        // the audio badge must sit above the full-size click area, or its clicks never arrive
        b = make({ display: "player", AppPid: 42, AppId: "player" })
        const kids = Array.from(b.children)
        const badge = kids.find(c => c.objectName === "audioBadge")
        const click = kids.find(c => c.toString().indexOf("MouseArea") >= 0)
        if (!badge || !click || badge.z <= click.z) return fail("audio badge must stack above the click area")

        // running window: click activates, active window click minimizes
        b = make({ display: "w", AppPid: 5, AppId: "w", IsActive: false })
        b.activate()
        if (calls.pop() !== "activate") return fail("activate")
        b = make({ display: "w", AppPid: 5, AppId: "w", IsActive: true })
        b.activate()
        if (calls.pop() !== "minimize") return fail("minimize")

        // pinned launcher that is not running: click starts it, pid 0 resolves no exe, close disabled
        b = make({ display: "Files", AppId: "files", IsLauncher: true, HasLauncher: true, LauncherUrlWithoutIcon: "file:///files.desktop" })
        if (!b.launcher || !b.pinned) return fail("launcher flags")
        b.activate()
        if (calls.pop() !== "newInstance") return fail("launch")
        b.togglePin()
        if (calls.pop() !== "remove:file:///files.desktop") return fail("unpin")

        // running but unpinned window can be pinned
        b = make({ display: "w", AppPid: 5, AppId: "w", HasLauncher: false, LauncherUrlWithoutIcon: "file:///w.desktop" })
        b.togglePin()
        if (calls.pop() !== "add:file:///w.desktop") return fail("pin")

        // live drag: pointer positions are along the list axis; the button follows the pointer
        // and asks for a move as soon as its centre crosses into another cell
        b = make({ display: "w", AppPid: 5, AppId: "w" })
        b.cellSize = 100; b.count = 4; b.index = 1       // cell 1 starts at x=100
        b.x = 100
        let moves = []
        b.moveRequested.connect(t => moves.push(t))
        b.beginDrag(130)                                  // grabbed 30px into the button
        b.moveDrag(133)
        if (b.dragging || b.renderDelta !== 0 || moves.length) return fail("tiny movement must not drag")
        b.endDrag()
        if (b.wasDragged) return fail("tiny movement is a click")
        b.beginDrag(130)
        b.moveDrag(150)                                   // dragged 20px right: centre 170, still cell 1
        if (!b.dragging || b.dragDelta !== 20 || moves.length) return fail("follows pointer: " + b.dragDelta + " moves " + moves)
        b.moveDrag(250)                                   // dragged 120px: centre 270, cell 2
        if (b.dragDelta !== 120 || moves.join() !== "2") return fail("live move: " + b.dragDelta + " moves " + moves)
        b.moveDrag(10)                                    // far left: centre -90, clamped to cell 0
        if (moves.join() !== "2,0") return fail("clamped move: " + moves)
        b.endDrag()
        if (b.dragging || !b.wasDragged) return fail("drag end flags")

        // vertical lists use the same logic along y
        b = make({ display: "w", AppPid: 5, AppId: "w" })
        b.vertical = true; b.cellSize = 30; b.count = 3; b.index = 0; b.y = 0
        moves = []
        b.moveRequested.connect(t => moves.push(t))
        b.beginDrag(10); b.moveDrag(50)
        if (moves.join() !== "1") return fail("vertical live move: " + moves)

        // rule action: adds a matching rule only when none exists, then asks for the config dialog
        let asked = 0
        b = make({ display: "w", AppPid: 5, AppId: "new" })
        b.ruleRequested.connect(() => asked++)
        if (b.hasRule) return fail("no rule yet")
        b.addOrEditRule()
        if (store.added.join() !== "new" || asked !== 1) return fail("add rule: " + store.added + " " + asked)
        b = make({ display: "w", AppPid: 5, AppId: "ruled" })
        b.ruleRequested.connect(() => asked++)
        if (!b.hasRule) return fail("rule exists")
        b.addOrEditRule()
        if (store.added.length !== 1 || asked !== 2) return fail("edit must not add: " + store.added)

        console.log("PASS")
        Qt.exit(0)
    }
}
