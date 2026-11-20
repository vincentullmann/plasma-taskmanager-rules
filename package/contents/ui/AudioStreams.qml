import QtQml
import org.kde.plasma.private.volume

// Per-process view of PulseAudio playback streams, so a task can show "playing" and be muted.
QtObject {
    id: audio

    // Bumps whenever a stream appears, disappears, pauses or is muted, so bindings re-evaluate.
    property int revision: 0

    // {hasAudio, playing, muted} for the streams owned by `pid`.
    function state(pid) {
        revision
        const s = { hasAudio: false, playing: false, muted: false }
        if (!(pid > 0)) return s
        for (let i = 0; i < streams.count; i++) {
            const o = streams.objectAt(i)
            if (o && o.pid === pid) {
                s.hasAudio = true
                s.playing = s.playing || !o.corked
                s.muted = s.muted || o.muted
            }
        }
        return s
    }

    function setMuted(pid, muted) {
        for (let i = 0; i < streams.count; i++) {
            const o = streams.objectAt(i)
            if (o && o.pid === pid) o.stream.muted = muted
        }
    }

    property Instantiator streams: Instantiator {
        model: PulseObjectFilterModel {
            filters: [{ role: "VirtualStream", value: false }]
            sourceModel: SinkInputModel {}
        }
        delegate: QtObject {
            required property var model
            readonly property var stream: model.PulseObject
            readonly property int pid: {
                const p = stream && stream.client ? stream.client.properties["application.process.id"] : undefined
                return p ? parseInt(p) : 0
            }
            readonly property bool corked: stream ? stream.corked : true
            readonly property bool muted: stream ? stream.muted : false
            onCorkedChanged: audio.revision++
            onMutedChanged: audio.revision++
            onPidChanged: audio.revision++
        }
        onObjectAdded: audio.revision++
        onObjectRemoved: audio.revision++
    }
}
