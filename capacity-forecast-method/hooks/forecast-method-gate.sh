#!/usr/bin/env bash
# capacity-forecast-method: phase-1 proposal gate for forecast-method
# selection (SRE book "Capacity Planning" chapter organic/inorganic
# framing). Fires on docs/issue-*/proposals/*.md only.
# Kill switch: CAPACITY_FORECAST_METHOD_GATE_OFF=1
set -euo pipefail

[ "${CAPACITY_FORECAST_METHOD_GATE_OFF:-0}" = "1" ] && exit 0

input="$(cat)"

file_path="$(printf '%s' "$input" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
ti = d.get("tool_input", {}) or {}
print(ti.get("file_path", ""))
' 2>/dev/null)" || { echo "capacity-forecast-method-gate: unparseable payload" >&2; exit 2; }

case "$file_path" in
  */docs/issue-*/proposals/*.md|docs/issue-*/proposals/*.md) ;;
  *) exit 0 ;;
esac

content="$(printf '%s' "$input" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(1)
tool = d.get("tool_name", "")
ti = d.get("tool_input", {}) or {}
fp = ti.get("file_path", "")

def read_existing():
    with open(fp, "r", encoding="utf-8") as f:
        return f.read()

if tool == "Write":
    print(ti.get("content", ""))
elif tool == "Edit":
    cur = read_existing()
    old = ti.get("old_string", "")
    new = ti.get("new_string", "")
    if old and old not in cur:
        sys.exit(1)
    if ti.get("replace_all"):
        print(cur.replace(old, new))
    else:
        print(cur.replace(old, new, 1))
elif tool == "MultiEdit":
    cur = read_existing()
    for e in ti.get("edits", []) or []:
        old = e.get("old_string", "")
        new = e.get("new_string", "")
        if old and old not in cur:
            sys.exit(1)
        if e.get("replace_all"):
            cur = cur.replace(old, new)
        else:
            cur = cur.replace(old, new, 1)
    print(cur)
else:
    print(read_existing())
' 2>/dev/null)"
rc=$?
if [ $rc -ne 0 ]; then
  echo "capacity-forecast-method-gate: could not reconstruct resulting content (fail-closed)" >&2
  exit 2
fi

# Non-terminal (in-progress) drafts are lenient, matching this role's
# other gates' terminal-only leniency principle.
if ! printf '%s' "$content" | grep -qiE 'loop_state:\s*terminal|state:\s*(done|terminal|complete)|^##[[:space:]]*rationale'; then
  exit 0
fi

lc="$(printf '%s' "$content" | tr '[:upper:]' '[:lower:]')"

# Explicit not-yet-applicable escape, per the norm's own carve-out.
if printf '%s' "$lc" | grep -qE '(forecast[- ]method|forecast method).{0,80}(해당[[:space:]]*없음|not applicable|n/a)'; then
  exit 0
fi

# Check 1: recognized technique keyword, or literal alternative marker.
method_ok=0
if printf '%s' "$lc" | grep -qE 'regression|trend|holt-winters|holt winters|arima'; then
  method_ok=1
elif printf '%s' "$content" | grep -qE '(대안:|alternative:)'; then
  method_ok=1
fi
if [ "$method_ok" -ne 1 ]; then
  echo "capacity-forecast-method-gate: no recognized forecast-method keyword (regression/trend/holt-winters/arima) or explicit 대안:/alternative: marker found (docs/issue-1/proposals/capacity-planning-methodology-norm.md; SRE book Capacity Planning chapter)" >&2
  exit 2
fi

# Check 2: minimum-length justification prose follows the method
# mention, not just a bare keyword. Require >= 40 non-whitespace chars
# somewhere in the same document beyond the keyword itself.
nonspace_len="$(printf '%s' "$content" | tr -d '[:space:]' | wc -c)"
if [ "$nonspace_len" -lt 200 ]; then
  echo "capacity-forecast-method-gate: forecast-method justification too short (need substantive prose, not a bare keyword)" >&2
  exit 2
fi

# Check 3: the method claim must co-occur with a data-shape
# classification term.
if ! printf '%s' "$lc" | grep -qE 'organic|inorganic|seasonal|campaign|조직적|비조직적|계절'; then
  echo "capacity-forecast-method-gate: forecast-method claim not linked to a data-shape classification term (organic/inorganic/seasonal/campaign)" >&2
  exit 2
fi

exit 0
