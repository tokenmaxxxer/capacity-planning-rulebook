#!/usr/bin/env bash
# Role-owned PreToolUse gate for capacity-planning's phase-2 record.
# Additive to core's generic record-fields-gate.sh; does not replace it.
# Kill switch: CAPACITY_FIELDS_GATE_OFF=1
set -euo pipefail

[ "${CAPACITY_FIELDS_GATE_OFF:-0}" = "1" ] && exit 0

input="$(cat)"

file_path="$(printf '%s' "$input" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
ti = d.get("tool_input", {}) or {}
print(ti.get("file_path", ""))
' 2>/dev/null || true)"

# Only fires on this role's own record path.
case "$file_path" in
  */docs/issue-*/reports/capacity-planning.md|docs/issue-*/reports/capacity-planning.md) ;;
  *) exit 0 ;;
esac

# Reconstruct the resulting content this write would produce.
content="$(printf '%s' "$input" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
tool = d.get("tool_name", "")
ti = d.get("tool_input", {}) or {}
fp = ti.get("file_path", "")

def read_existing():
    try:
        with open(fp, "r", encoding="utf-8") as f:
            return f.read()
    except Exception:
        return ""

if tool == "Write":
    print(ti.get("content", ""))
elif tool == "Edit":
    cur = read_existing()
    old = ti.get("old_string", "")
    new = ti.get("new_string", "")
    if ti.get("replace_all"):
        print(cur.replace(old, new))
    else:
        print(cur.replace(old, new, 1))
elif tool == "MultiEdit":
    cur = read_existing()
    for e in ti.get("edits", []) or []:
        old = e.get("old_string", "")
        new = e.get("new_string", "")
        if e.get("replace_all"):
            cur = cur.replace(old, new)
        else:
            cur = cur.replace(old, new, 1)
    print(cur)
else:
    print(read_existing())
' 2>/dev/null || true)"

[ -z "$content" ] && exit 0

# Leniency: non-terminal (in-progress) writes are not blocked, matching
# record-fields-gate.sh's own next-steps leniency principle.
if ! printf '%s' "$content" | grep -qiE 'loop_state:\s*terminal|state:\s*(done|terminal|complete)'; then
  exit 0
fi

missing=""

printf '%s' "$content" | grep -qE '^#+[[:space:]]*.*(Capacity forecast|capacity forecast)' \
  || missing="${missing}- Capacity forecast subsection heading missing\n"

printf '%s' "$content" | grep -qE '^#+[[:space:]]*.*(Expansion trigger thresholds|expansion trigger thresholds)' \
  || missing="${missing}- Expansion trigger thresholds subsection heading missing\n"

printf '%s' "$content" | grep -qE '^#+[[:space:]]*.*(Cost note|cost note)' \
  || missing="${missing}- Cost note subsection heading missing\n"

if printf '%s' "$content" | grep -qE '^#+[[:space:]]*.*(Expansion trigger thresholds|expansion trigger thresholds)'; then
  printf '%s' "$content" | grep -qiE 'growth_rate|성장률' \
    || missing="${missing}- Threshold subsection missing growth_rate term\n"
  printf '%s' "$content" | grep -qiE 'lead_time|리드타임|조달\s*기간' \
    || missing="${missing}- Threshold subsection missing lead_time term\n"
  printf '%s' "$content" | grep -qiE 'safety_buffer|안전\s*버퍼' \
    || missing="${missing}- Threshold subsection missing safety_buffer term\n"
  printf '%s' "$content" | grep -qiE 'p[0-9]{1,3}(\.[0-9]+)?|percentile|백분위' \
    || missing="${missing}- Threshold subsection missing a percentile token\n"
fi

if [ -n "$missing" ]; then
  {
    echo "capacity-fields-gate: terminal capacity-planning record fails issue-1 norm (docs/issue-1/proposals/capacity-planning-methodology-norm.md §b):"
    printf '%b' "$missing"
  } >&2
  exit 2
fi

exit 0
