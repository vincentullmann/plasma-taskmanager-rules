// Pure helpers for the task list (drag reorder, audio and progress badges).
// Same dual-environment rules as rules.js: top-level functions for QML, module.exports for node.

// Index of the cell under `pos` (px along the list axis) for `count` equally sized cells; clamped.
function dropIndex(pos, cellSize, count) {
    if (count <= 0 || cellSize <= 0) return 0;
    var i = Math.floor(pos / cellSize);
    return Math.max(0, Math.min(count - 1, i));
}

// Badge state for a window's audio stream. Visible while playing, or while muted (so it can be unmuted).
function audioBadge(s) {
    var show = !!s.hasAudio && (!!s.playing || !!s.muted);
    if (!show) return { visible: false, icon: "", muted: false };
    return { visible: true, icon: s.muted ? "audio-volume-muted" : "audio-volume-high", muted: !!s.muted };
}

// Progress of a launcher entry as 0..1, or -1 when no progress bar should be shown.
function progressFraction(p) {
    if (!p || !p.visible || typeof p.value !== "number" || isNaN(p.value)) return -1;
    return Math.max(0, Math.min(1, p.value));
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = { dropIndex: dropIndex, audioBadge: audioBadge, progressFraction: progressFraction };
}
