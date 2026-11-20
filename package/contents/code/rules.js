// Rule engine: pure JS, no Qt imports. Runs under node (tests) and in QML (`import "..." as Rules`).
// Top-level function declarations are what QML exposes; the module.exports tail is for node only.

var CONDITION_FIELDS = ["title", "appId", "name", "exe"];
var MATCHER_TYPES = ["exact", "regex", "glob"];
var ACTION_KEYS = ["icon", "fontColor", "background"];
var COLOR_RE = /^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/;

function defaultConfig() {
    return { version: 1, rules: [] };
}

function _isObject(v) {
    return v !== null && typeof v === "object" && !Array.isArray(v);
}

function _label(i, rule) {
    var s = "rules[" + i + "]";
    if (_isObject(rule) && typeof rule.name === "string" && rule.name !== "")
        s += ' ("' + rule.name + '")';
    return s;
}

function _compileMatcher(type, value, caseSensitive) {
    var flags = caseSensitive ? "" : "i";
    if (type === "exact") {
        var needle = caseSensitive ? value : value.toLowerCase();
        return function (s) { return (caseSensitive ? s : s.toLowerCase()) === needle; };
    }
    var re;
    if (type === "regex") {
        re = new RegExp(value, flags);
    } else {
        var src = "";
        for (var i = 0; i < value.length; i++) {
            var c = value[i];
            if (c === "*") src += "[\\s\\S]*";
            else if (c === "?") src += "[\\s\\S]";
            else src += c.replace(/[.*+?^${}()|[\]\\\/-]/g, "\\$&");
        }
        re = new RegExp("^" + src + "$", flags);
    }
    return function (s) { return re.test(s); };
}

// Returns { ok, errors: [string] }. Collects every error.
function validate(config) {
    var errors = [];
    if (!_isObject(config)) return { ok: false, errors: ["config must be an object"] };
    if (config.version !== 1) errors.push("version must be 1");
    if (!Array.isArray(config.rules)) {
        errors.push("rules must be an array");
        return { ok: false, errors: errors };
    }
    config.rules.forEach(function (rule, i) {
        var at = _label(i, rule);
        if (!_isObject(rule)) { errors.push(at + " must be an object"); return; }
        if (rule.name !== undefined && typeof rule.name !== "string") errors.push(at + ".name must be a string");
        if (rule.enabled !== undefined && typeof rule.enabled !== "boolean") errors.push(at + ".enabled must be a boolean");

        if (!_isObject(rule.conditions)) {
            errors.push(at + ".conditions must be an object");
        } else {
            var keys = Object.keys(rule.conditions);
            if (keys.length === 0) errors.push(at + " needs at least one condition");
            keys.forEach(function (field) {
                var cat = at + ".conditions." + field;
                if (CONDITION_FIELDS.indexOf(field) < 0) {
                    errors.push(at + ': unknown condition field "' + field + '" (use ' + CONDITION_FIELDS.join(", ") + ")");
                    return;
                }
                var m = rule.conditions[field];
                if (!_isObject(m)) { errors.push(cat + " must be an object like {\"exact\": \"...\"}"); return; }
                var present = MATCHER_TYPES.filter(function (t) { return m[t] !== undefined; });
                if (present.length !== 1) {
                    errors.push(cat + " needs exactly one of exact, regex, glob");
                } else if (typeof m[present[0]] !== "string") {
                    errors.push(cat + "." + present[0] + " must be a string");
                } else if (present[0] === "regex") {
                    try { new RegExp(m.regex); } catch (e) {
                        errors.push(cat + ".regex is not a valid regular expression: " + e.message);
                    }
                }
                if (m.caseSensitive !== undefined && typeof m.caseSensitive !== "boolean")
                    errors.push(cat + ".caseSensitive must be a boolean");
            });
        }

        if (!_isObject(rule.actions)) {
            errors.push(at + ".actions must be an object");
        } else {
            var a = rule.actions;
            if (a.icon !== undefined && typeof a.icon !== "string") errors.push(at + ".actions.icon must be a string");
            ["fontColor", "background"].forEach(function (k) {
                if (a[k] !== undefined && !(typeof a[k] === "string" && COLOR_RE.test(a[k])))
                    errors.push(at + ".actions." + k + " must be #RRGGBB or #AARRGGBB");
            });
        }
    });
    return { ok: errors.length === 0, errors: errors };
}

// Theme name, or a path when it starts with "/" or "~" (a lone "~" or "~/..."; "~x" stays a name).
function resolveIcon(value, home) {
    if (value.charAt(0) === "/") return { path: value };
    if (value === "~" || value.indexOf("~/") === 0) {
        var h = (home || "").replace(/\/+$/, "");
        return { path: h + value.substring(1) };
    }
    return { name: value };
}

// Validate and precompile (regexes built once). opts.home is used to expand "~" in icon paths.
function compile(config, opts) {
    var v = validate(config);
    if (!v.ok) return { ok: false, errors: v.errors };
    var home = (opts && opts.home) || "";
    var rules = [];
    config.rules.forEach(function (rule) {
        if (rule.enabled === false) return;
        var tests = Object.keys(rule.conditions).map(function (field) {
            var m = rule.conditions[field];
            var type = MATCHER_TYPES.filter(function (t) { return m[t] !== undefined; })[0];
            return { field: field, test: _compileMatcher(type, m[type], m.caseSensitive === true) };
        });
        var actions = {};
        if (rule.actions.icon !== undefined) actions.icon = resolveIcon(rule.actions.icon, home);
        if (rule.actions.fontColor !== undefined) actions.fontColor = rule.actions.fontColor;
        if (rule.actions.background !== undefined) actions.background = rule.actions.background;
        rules.push({ tests: tests, actions: actions });
    });
    return { ok: true, errors: [], engine: { rules: rules } };
}

// window: { title, appId, name, exe }. Returns merged actions: later rules win per field.
function evaluate(engine, window) {
    var out = {};
    engine.rules.forEach(function (r) {
        for (var i = 0; i < r.tests.length; i++) {
            var val = window[r.tests[i].field];
            if (!r.tests[i].test(val === undefined || val === null ? "" : String(val))) return;
        }
        ACTION_KEYS.forEach(function (k) { if (r.actions[k] !== undefined) out[k] = r.actions[k]; });
    });
    return out;
}

// Parse JSON text and validate. Returns { ok, config?, errors }.
function parse(text) {
    var config;
    try { config = JSON.parse(text); } catch (e) {
        return { ok: false, errors: ["invalid JSON: " + e.message] };
    }
    var v = validate(config);
    return v.ok ? { ok: true, config: config, errors: [] } : { ok: false, errors: v.errors };
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = { defaultConfig: defaultConfig, validate: validate, compile: compile, evaluate: evaluate,
                       resolveIcon: resolveIcon, parse: parse,
                       CONDITION_FIELDS: CONDITION_FIELDS, MATCHER_TYPES: MATCHER_TYPES };
}
