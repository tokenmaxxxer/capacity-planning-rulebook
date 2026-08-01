#!/usr/bin/env bash
# Role-owned PreToolUse gate for capacity-planning's phase-2 record.
# Additive to core's generic record-fields-gate.sh; does not replace it.
# Kill switch: CAPACITY_FIELDS_GATE_OFF=1
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "capacity-fields-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
set -uo pipefail

gate_kill_switch_active "${CAPACITY_FIELDS_GATE_OFF:-}" || { trap - EXIT; exit 0; }

input="$(cat)"

file_path="$(printf '%s' "$input" | python3 -c '
import importlib.util, os
_spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
gate_lib = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(gate_lib)

import re, sys

def deny(msg):
    sys.stderr.write(msg)
    sys.exit(2)

raw = sys.stdin.read()
d = gate_lib.gate_parse_json_or_deny(raw, deny)
ti = d.get("tool_input", {}) or {}
fp = ti.get("file_path", "")
root = os.path.realpath(os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd()))
tail = gate_lib.gate_normalize_path(root, fp)
if tail is not None and re.match(r"^docs/issue-\d+/reports/capacity-planning\.md$", tail):
    print(tail)
')"
rc=$?
[ "$rc" != 0 ] && gate_deny "capacity-fields-gate" "malformed tool-call payload"

# Only fires on this role's own record path.
[ -z "$file_path" ] && gate_allow

# Reconstruct the resulting content this write would produce.
content="$(printf '%s' "$input" | python3 -c '
import importlib.util, os
_spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
gate_lib = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(gate_lib)

import sys

def deny(msg):
    sys.stderr.write(msg)
    sys.exit(2)

raw = sys.stdin.read()
d = gate_lib.gate_parse_json_or_deny(raw, deny)
tool = d.get("tool_name", "")
ti = d.get("tool_input", {}) or {}
fp = ti.get("file_path", "")

def read_existing():
    try:
        with open(fp, "r", encoding="utf-8") as f:
            return f.read()
    except Exception:
        return None

current = read_existing()
new_text, ok = gate_lib.gate_reconstruct_write(tool, ti, current)
if not ok:
    deny("cannot reconstruct the resulting content for this tool call; refusing to guess")
print(new_text if new_text is not None else "")
')"
rc=$?
[ "$rc" != 0 ] && gate_deny "capacity-fields-gate" "cannot reconstruct the resulting content for this tool call; refusing to guess"

[ -z "$content" ] && gate_allow

# Leniency: non-terminal (in-progress) writes are not blocked, matching
# record-fields-gate.sh's own next-steps leniency principle.
if ! printf '%s' "$content" | grep -qiE 'loop_state:\s*terminal|state:\s*(done|terminal|complete)'; then
  gate_allow
fi

missing=""

printf '%s' "$content" | grep -qE '^#+[[:space:]]*.*(Capacity forecast|capacity forecast)' \
  || missing="${missing}- Capacity forecast subsection heading missing\n"

printf '%s' "$content" | grep -qE '^#+[[:space:]]*.*(Expansion trigger thresholds|expansion trigger thresholds)' \
  || missing="${missing}- Expansion trigger thresholds subsection heading missing\n"

printf '%s' "$content" | grep -qE '^#+[[:space:]]*.*(Cost note|cost note)' \
  || missing="${missing}- Cost note subsection heading missing\n"

if printf '%s' "$content" | grep -qE '^#+[[:space:]]*.*(Expansion trigger thresholds|expansion trigger thresholds)'; then
  threshold_slice="$(printf '%s' "$content" | python3 -c '
import importlib.util, os
_spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
gate_lib = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(gate_lib)

import re, sys
content = sys.stdin.read()
m = re.search(
    r"^#+[^\n]*Expansion trigger thresholds[^\n]*\n(.*?)(?=\n#+\s|\Z)",
    content, re.I | re.M | re.S,
)
if m:
    sys.stdout.write(m.group(1))
')"

  printf '%s' "$threshold_slice" | grep -qiE 'growth_rate|성장률' \
    || missing="${missing}- Threshold subsection missing growth_rate term\n"
  printf '%s' "$threshold_slice" | grep -qiE 'lead_time|리드타임|조달\s*기간' \
    || missing="${missing}- Threshold subsection missing lead_time term\n"
  printf '%s' "$threshold_slice" | grep -qiE 'safety_buffer|안전\s*버퍼' \
    || missing="${missing}- Threshold subsection missing safety_buffer term\n"
  printf '%s' "$threshold_slice" | grep -qiE 'p[0-9]{1,3}(\.[0-9]+)?|percentile|백분위' \
    || missing="${missing}- Threshold subsection missing a percentile token\n"
fi

if [ -n "$missing" ]; then
  reason="terminal capacity-planning record fails issue-1 norm (docs/issue-1/proposals/capacity-planning-methodology-norm.md §b): $(printf '%b' "$missing")"
  gate_deny "capacity-fields-gate" "$reason"
fi

gate_allow
