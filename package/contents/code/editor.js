// Pure edit operations for the rule editor. Every function takes a config and returns a new one
// (inputs are never mutated), so QML can swap the draft and bindings update.
// Same dual-environment rules as rules.js: top-level functions for QML, module.exports for node.

var FIELDS = ["title", "appId", "name", "exe"];   // keep in sync with rules.js CONDITION_FIELDS
var TYPES = ["exact", "regex", "glob"];           // keep in sync with rules.js MATCHER_TYPES

function _clone(v) { return JSON.parse(JSON.stringify(v)); }

// Clone the config, run fn on the cloned rule at index; out-of-range index returns the clone.
function _withRule(config, index, fn) {
    var c = _clone(config);
    if (index >= 0 && index < c.rules.length) fn(c.rules[index]);
    return c;
}

function _matcherType(m) {
    for (var i = 0; i < TYPES.length; i++) if (m[TYPES[i]] !== undefined) return TYPES[i];
    return "exact";
}

function addRule(config) {
    var c = _clone(config);
    // An exact match on "" is inert, so a fresh rule never changes anything until it is edited.
    c.rules.push({ enabled: true, conditions: { appId: { exact: "" } }, actions: {} });
    return c;
}

function removeRule(config, index) {
    var c = _clone(config);
    if (index >= 0 && index < c.rules.length) c.rules.splice(index, 1);
    return c;
}

// delta: -1 = earlier (lower priority), +1 = later (higher priority). Clamped.
function moveRule(config, index, delta) {
    var c = _clone(config);
    var to = index + delta;
    if (index < 0 || index >= c.rules.length || to < 0 || to >= c.rules.length) return c;
    var r = c.rules.splice(index, 1)[0];
    c.rules.splice(to, 0, r);
    return c;
}

function setRuleProp(config, index, key, value) {
    return _withRule(config, index, function (r) { r[key] = value; });
}

// [{ field, type, value, caseSensitive }] in stored order, for display.
function conditionList(rule) {
    return Object.keys(rule.conditions || {}).map(function (field) {
        var m = rule.conditions[field];
        var type = _matcherType(m);
        return { field: field, type: type, value: m[type] === undefined ? "" : m[type], caseSensitive: m.caseSensitive === true };
    });
}

function addCondition(config, index) {
    return _withRule(config, index, function (r) {
        for (var i = 0; i < FIELDS.length; i++) {
            if (r.conditions[FIELDS[i]] === undefined) { r.conditions[FIELDS[i]] = { exact: "" }; return; }
        }
    });
}

// spec: { type, value, caseSensitive }
function setCondition(config, index, field, spec) {
    return _withRule(config, index, function (r) {
        var m = {};
        m[spec.type] = spec.value;
        if (spec.caseSensitive) m.caseSensitive = true;
        r.conditions[field] = m;
    });
}

// Rename a condition's field in place (keeps order); no-op if the new field is already used.
function changeConditionField(config, index, oldField, newField) {
    return _withRule(config, index, function (r) {
        if (oldField === newField || r.conditions[newField] !== undefined || r.conditions[oldField] === undefined) return;
        var out = {};
        Object.keys(r.conditions).forEach(function (k) {
            out[k === oldField ? newField : k] = r.conditions[k];
        });
        r.conditions = out;
    });
}

function removeCondition(config, index, field) {
    return _withRule(config, index, function (r) { delete r.conditions[field]; });
}

// Empty string or undefined clears the action.
function setAction(config, index, key, value) {
    return _withRule(config, index, function (r) {
        if (value === undefined || value === "") delete r.actions[key];
        else r.actions[key] = value;
    });
}

function regexError(pattern) {
    try { new RegExp(pattern); return ""; } catch (e) { return e.message; }
}

function conditionError(cond) {
    return cond.type === "regex" ? regexError(cond.value) : "";
}

function colorError(value) {
    if (value === "" || /^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(value)) return "";
    return "use #RRGGBB or #AARRGGBB";
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = { FIELDS: FIELDS, TYPES: TYPES, addRule: addRule, removeRule: removeRule, moveRule: moveRule,
                       setRuleProp: setRuleProp, conditionList: conditionList, addCondition: addCondition,
                       setCondition: setCondition, changeConditionField: changeConditionField,
                       removeCondition: removeCondition, setAction: setAction, regexError: regexError,
                       conditionError: conditionError, colorError: colorError };
}
