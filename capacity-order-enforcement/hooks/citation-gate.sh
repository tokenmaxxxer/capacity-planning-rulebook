#!/usr/bin/env bash
# capacity-order-enforcement: phase-1 proposal and phase-1 report
# (scout-brief) surfaces. Enforces the survey -> scout-brief -> proposal
# citation chain in lieu of a separate state file. survey.md itself is
# exempt (it is the root of the order).
# Kill switch: CAPACITY_ORDER_ENFORCEMENT_GATE_OFF=1
set -euo pipefail

[ "${CAPACITY_ORDER_ENFORCEMENT_GATE_OFF:-0}" = "1" ] && exit 0

input="$(cat)"

file_path="$(printf '%s' "$input" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
ti = d.get("tool_input", {}) or {}
print(ti.get("file_path", ""))
' 2>/dev/null)" || { echo "capacity-order-enforcement-gate: unparseable payload" >&2; exit 2; }

kind=""
case "$file_path" in
  */docs/issue-*/proposals/*.md|docs/issue-*/proposals/*.md) kind=proposal ;;
  */docs/issue-*/reports/capacity-planning/scout-brief.md|docs/issue-*/reports/capacity-planning/scout-brief.md) kind=scout-brief ;;
  */docs/issue-*/reports/capacity-planning/survey.md|docs/issue-*/reports/capacity-planning/survey.md) exit 0 ;;
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
  echo "capacity-order-enforcement-gate: could not reconstruct resulting content (fail-closed)" >&2
  exit 2
fi

if [ "$kind" = "scout-brief" ]; then
  # scout-brief cites survey.md; non-terminal drafts (mid-write) exempt.
  if ! printf '%s' "$content" | grep -qiE 'loop_state:\s*terminal|state:\s*(done|terminal|complete)|^##[[:space:]]*sources'; then
    exit 0
  fi
  if ! printf '%s' "$content" | grep -qE 'survey\.md'; then
    echo "capacity-order-enforcement-gate: scout-brief.md does not cite survey.md by filename" >&2
    exit 2
  fi
  exit 0
fi

# proposal: cite survey.md and scout-brief.md once terminal-looking.
if ! printf '%s' "$content" | grep -qiE 'loop_state:\s*terminal|state:\s*(done|terminal|complete)|^##[[:space:]]*rationale'; then
  exit 0
fi

missing=""
printf '%s' "$content" | grep -qE 'survey\.md' || missing="${missing}- proposal does not cite survey.md by filename\n"
printf '%s' "$content" | grep -qE 'scout-brief\.md' || missing="${missing}- proposal does not cite scout-brief.md by filename\n"

if [ -n "$missing" ]; then
  {
    echo "capacity-order-enforcement-gate: proposal fails document-sequencing precondition:"
    printf '%b' "$missing"
  } >&2
  exit 2
fi

exit 0
