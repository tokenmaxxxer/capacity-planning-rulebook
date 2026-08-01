#!/usr/bin/env bash
# capacity-forecast-method: phase-1 proposal gate for forecast-method
# selection (SRE book "Capacity Planning" chapter organic/inorganic
# framing). Fires on docs/issue-*/proposals/*.md only.
# Kill switch: CAPACITY_FORECAST_METHOD_GATE_OFF=1
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "forecast-method-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
set -uo pipefail

gate_kill_switch_active "${CAPACITY_FORECAST_METHOD_GATE_OFF:-}" || { trap - EXIT; exit 0; }

input="$(cat)"

file_path="$(printf '%s' "$input" | python3 -c '
import importlib.util, os, re, sys
_spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
gate_lib = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(gate_lib)

def deny(msg):
    sys.stderr.write(msg + "\n")
    sys.exit(2)

raw = sys.stdin.read()
d = gate_lib.gate_parse_json_or_deny(raw, deny)
ti = d.get("tool_input", {}) or {}
fp = ti.get("file_path", "")

root = os.path.realpath(os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd()))
tail = gate_lib.gate_normalize_path(root, fp)
if tail is not None and re.match(r"^docs/issue-\d+/proposals/.*\.md$", tail):
    print(tail)
')"
rc=$?
if [ "$rc" != 0 ]; then
  gate_deny "capacity-forecast-method-gate" "malformed tool-call payload"
fi
if [ -z "$file_path" ]; then
  gate_allow
fi

content="$(printf '%s' "$input" | python3 -c '
import importlib.util, os, sys
_spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
gate_lib = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(gate_lib)

def deny(msg):
    sys.stderr.write(msg + "\n")
    sys.exit(2)

raw = sys.stdin.read()
d = gate_lib.gate_parse_json_or_deny(raw, deny)
tool = d.get("tool_name", "")
ti = d.get("tool_input", {}) or {}
fp = ti.get("file_path", "")

current = None
try:
    with open(fp, "r", encoding="utf-8") as f:
        current = f.read()
except Exception:
    current = None

text, ok = gate_lib.gate_reconstruct_write(tool, ti, current)
if not ok:
    deny("capacity-forecast-method-gate: could not reconstruct resulting content (fail-closed)")
print(text)
')"
rc=$?
if [ "$rc" != 0 ]; then
  gate_deny "capacity-forecast-method-gate" "could not reconstruct resulting content (fail-closed)"
fi

# Non-terminal (in-progress) drafts are lenient, matching this role's
# other gates' terminal-only leniency principle.
if ! printf '%s' "$content" | grep -qiE 'loop_state:\s*terminal|state:\s*(done|terminal|complete)|^##[[:space:]]*rationale'; then
  gate_allow
fi

lc="$(printf '%s' "$content" | tr '[:upper:]' '[:lower:]')"

# Explicit not-yet-applicable escape, per the norm's own carve-out.
if printf '%s' "$lc" | grep -qE '(forecast[- ]method|forecast method).{0,80}(해당[[:space:]]*없음|not applicable|n/a)'; then
  gate_allow
fi

# Adjacency check: the recognized method keyword (or literal alternative
# marker) and the data-shape classification term must co-occur within a
# bounded window of each other, with >= 40 non-whitespace chars of
# substantive prose in between. This subsumes the old separate
# keyword-existence check and data-shape-term-existence check, since it
# now requires them to be near each other with real prose, not just
# present anywhere in the document.
adjacency_ok="$(printf '%s' "$content" | python3 -c '
import importlib.util, os, re, sys
_spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
gate_lib = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(gate_lib)

content = sys.stdin.read()
lc = content.lower()

method = r"(regression|trend|holt-winters|holt winters|arima|대안:|alternative:)"
shape = r"(organic|inorganic|seasonal|campaign|조직적|비조직적|계절)"

found = False
for pattern in (method + r".{0,300}?" + shape, shape + r".{0,300}?" + method):
    for m in re.finditer(pattern, lc, re.S):
        whole = m.group(0)
        g1 = m.group(1)
        g2 = m.group(2)
        mid = whole[len(g1):len(whole) - len(g2)]
        nonspace = re.sub(r"\s+", "", mid)
        if len(nonspace) >= 40:
            found = True
            break
    if found:
        break

print("1" if found else "0")
')"

if [ "$adjacency_ok" != "1" ]; then
  gate_deny "capacity-forecast-method-gate" "forecast-method claim lacks a recognized method keyword (regression/trend/holt-winters/arima) or 대안:/alternative: marker adjacent (within ~300 chars) to a data-shape classification term (organic/inorganic/seasonal/campaign/조직적/비조직적/계절), with at least 40 non-whitespace chars of substantive justification prose between them (docs/issue-1/proposals/capacity-planning-methodology-norm.md; SRE book Capacity Planning chapter)"
fi

gate_allow
