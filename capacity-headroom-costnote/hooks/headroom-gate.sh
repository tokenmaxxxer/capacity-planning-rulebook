#!/usr/bin/env bash
# capacity-headroom-costnote: phase-2 record surface only, additive to
# core's record-fields-gate.sh and this role's capacity-fields-gate.sh.
# Universal Scalability Law: headroom must be a band, not a snapshot
# number; cost attributed to the firing threshold.
# Kill switch: CAPACITY_HEADROOM_GATE_OFF=1
set -euo pipefail

[ "${CAPACITY_HEADROOM_GATE_OFF:-0}" = "1" ] && exit 0

input="$(cat)"

file_path="$(printf '%s' "$input" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
ti = d.get("tool_input", {}) or {}
print(ti.get("file_path", ""))
' 2>/dev/null)" || { echo "capacity-headroom-gate: unparseable payload" >&2; exit 2; }

case "$file_path" in
  */docs/issue-*/reports/capacity-planning.md|docs/issue-*/reports/capacity-planning.md) ;;
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
  echo "capacity-headroom-gate: could not reconstruct resulting content (fail-closed)" >&2
  exit 2
fi

if ! printf '%s' "$content" | grep -qiE 'loop_state:\s*terminal|state:\s*(done|terminal|complete)'; then
  exit 0
fi

lc="$(printf '%s' "$content" | tr '[:upper:]' '[:lower:]')"
missing=""

# Band-not-snapshot: require a range token (a hyphenated/tilde number
# pair, or explicit "band"/"range"/대역/범위 language) somewhere near
# headroom language.
if printf '%s' "$lc" | grep -qE 'headroom|여유\s*용량|헤드룸'; then
  printf '%s' "$lc" | grep -qE '[0-9]+(\.[0-9]+)?[[:space:]]*(%|percent)?[[:space:]]*[-~][[:space:]]*[0-9]+(\.[0-9]+)?[[:space:]]*(%|percent)?|band|range|대역|범위' \
    || missing="${missing}- headroom stated as a snapshot number, not a band (Universal Scalability Law: margin degrades non-linearly near capacity)\n"
else
  missing="${missing}- no headroom figure found\n"
fi

# Cost-attributed-to-threshold: a cost note must name which threshold
# fired it, not just a bare figure.
if printf '%s' "$lc" | grep -qE 'cost|비용'; then
  printf '%s' "$lc" | grep -qE '(threshold|growth_rate|lead_time|safety_buffer|임계|기준).{0,120}(cost|비용)|(cost|비용).{0,120}(threshold|growth_rate|lead_time|safety_buffer|임계|기준)' \
    || missing="${missing}- cost note present but not attributed to a specific firing threshold\n"
else
  missing="${missing}- no cost note found\n"
fi

if [ -n "$missing" ]; then
  {
    echo "capacity-headroom-gate: headroom/cost fields fail issue-1 norm (docs/issue-1/proposals/capacity-planning-methodology-norm.md; Universal Scalability Law):"
    printf '%b' "$missing"
  } >&2
  exit 2
fi

exit 0
