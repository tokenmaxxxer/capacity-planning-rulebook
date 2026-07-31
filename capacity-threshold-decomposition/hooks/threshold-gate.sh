#!/usr/bin/env bash
# capacity-threshold-decomposition: fires on both the phase-1 proposal
# surface (docs/issue-*/proposals/*.md) and the phase-2 record surface
# (docs/issue-*/reports/capacity-planning.md). Little's Law
# (growth_rate x lead_time x safety_buffer): traceable numeric form,
# percentile-stated, never a bare flat percentage.
# Kill switch: CAPACITY_THRESHOLD_GATE_OFF=1
set -euo pipefail

[ "${CAPACITY_THRESHOLD_GATE_OFF:-0}" = "1" ] && exit 0

input="$(cat)"

file_path="$(printf '%s' "$input" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
ti = d.get("tool_input", {}) or {}
print(ti.get("file_path", ""))
' 2>/dev/null)" || { echo "capacity-threshold-gate: unparseable payload" >&2; exit 2; }

is_proposal=0
is_record=0
case "$file_path" in
  */docs/issue-*/proposals/*.md|docs/issue-*/proposals/*.md) is_proposal=1 ;;
  */docs/issue-*/reports/capacity-planning.md|docs/issue-*/reports/capacity-planning.md) is_record=1 ;;
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
  echo "capacity-threshold-gate: could not reconstruct resulting content (fail-closed)" >&2
  exit 2
fi

# Non-terminal drafts are lenient on the record surface, matching this
# role's other phase-2 gates; the proposal surface has no such draft
# marker so it is checked on any terminal-looking content (a rationale
# section present, matching the forecast-method gate's heuristic).
if [ "$is_record" -eq 1 ]; then
  if ! printf '%s' "$content" | grep -qiE 'loop_state:\s*terminal|state:\s*(done|terminal|complete)'; then
    exit 0
  fi
fi
if [ "$is_proposal" -eq 1 ]; then
  if ! printf '%s' "$content" | grep -qiE '^##[[:space:]]*rationale|loop_state:\s*terminal|state:\s*(done|terminal|complete)'; then
    exit 0
  fi
fi

# Only enforce if the document actually talks about the threshold at
# all -- a document with no growth-rate/lead-time/threshold figures
# yet is not this plugin's concern.
if ! printf '%s' "$content" | grep -qiE 'growth_rate|lead_time|safety_buffer|성장률|리드타임|안전\s*버퍼|threshold'; then
  exit 0
fi

lc="$(printf '%s' "$content" | tr '[:upper:]' '[:lower:]')"
missing=""

printf '%s' "$lc" | grep -qE 'growth_rate|성장률' || missing="${missing}- growth_rate term missing\n"
printf '%s' "$lc" | grep -qE 'lead_time|리드타임|조달\s*기간' || missing="${missing}- lead_time term missing\n"
printf '%s' "$lc" | grep -qE 'safety_buffer|안전\s*버퍼' || missing="${missing}- safety_buffer term missing\n"
printf '%s' "$lc" | grep -qE 'p[0-9]{1,3}(\.[0-9]+)?|percentile|백분위' || missing="${missing}- no percentile token (must be percentile-stated, not a bare figure)\n"

# Flat-percentage prohibition: a bare "NN%" with no percentile/labeling
# term nearby is rejected -- a lone percentage token unaccompanied by
# any of the three labeled terms or a percentile marker anywhere in the
# document signals a flat-percentage threshold.
if printf '%s' "$lc" | grep -qE '[0-9]+(\.[0-9]+)?[[:space:]]*%' \
   && ! printf '%s' "$lc" | grep -qE 'p[0-9]{1,3}(\.[0-9]+)?|percentile|백분위'; then
  missing="${missing}- bare flat-percentage figure found with no percentile qualifier (forbidden by Little's Law decomposition)\n"
fi

if [ -n "$missing" ]; then
  {
    echo "capacity-threshold-gate: threshold figures fail issue-1 norm (docs/issue-1/proposals/capacity-planning-methodology-norm.md; Little's Law growth_rate x lead_time x safety_buffer):"
    printf '%b' "$missing"
  } >&2
  exit 2
fi

exit 0
