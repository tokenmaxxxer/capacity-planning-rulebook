#!/usr/bin/env bash
# capacity-headroom-costnote: phase-2 record surface only, additive to
# core's record-fields-gate.sh and this role's capacity-fields-gate.sh.
# Universal Scalability Law: headroom must be a band, not a snapshot
# number; cost attributed to the firing threshold.
# Kill switch: CAPACITY_HEADROOM_GATE_OFF=1
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "headroom-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
set -uo pipefail

gate_kill_switch_active "${CAPACITY_HEADROOM_GATE_OFF:-}" || { trap - EXIT; exit 0; }

input="$(cat)"

file_path="$(printf '%s' "$input" | python3 -c '
import importlib.util, os, json, sys
_spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
gate_lib = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(gate_lib)

raw = sys.stdin.read()

def deny(msg):
    print(msg, file=sys.stderr)
    sys.exit(2)

d = gate_lib.gate_parse_json_or_deny(raw, deny)
ti = d.get("tool_input", {}) or {}
fp = ti.get("file_path", "")
root = os.path.realpath(os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd()))
scope = gate_lib.gate_normalize_path(root, fp)
import re
if scope is not None and re.match(r"^docs/issue-\d+/reports/capacity-planning\.md$", scope):
    print(scope)
')"
rc=$?
if [ $rc -ne 0 ]; then
  gate_deny "capacity-headroom-gate" "unparseable payload"
fi

if [ -z "$file_path" ]; then
  gate_allow
fi

content="$(printf '%s' "$input" | python3 -c '
import importlib.util, os, sys
_spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
gate_lib = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(gate_lib)

raw = sys.stdin.read()

def deny(msg):
    print(msg, file=sys.stderr)
    sys.exit(2)

d = gate_lib.gate_parse_json_or_deny(raw, deny)
tool = d.get("tool_name", "")
ti = d.get("tool_input", {}) or {}
fp = ti.get("file_path", "")

current = None
if os.path.exists(fp):
    with open(fp, "r", encoding="utf-8") as f:
        current = f.read()

text, ok = gate_lib.gate_reconstruct_write(tool, ti, current)
if not ok:
    sys.exit(2)
sys.stdout.write(text)
')"
rc=$?
if [ $rc -ne 0 ]; then
  gate_deny "capacity-headroom-gate" "could not reconstruct resulting content (fail-closed)"
fi

if ! printf '%s' "$content" | grep -qiE 'loop_state:\s*terminal|state:\s*(done|terminal|complete)'; then
  gate_allow
fi

# Scope the band-not-snapshot and cost-attribution checks to the
# headroom/cost-note heading's own slice, not the whole reconstructed
# document, so a stray "headroom"/"cost" mention elsewhere in a long
# record cannot satisfy the check via unrelated content. Fall back to
# the whole content if no such heading exists (same fallback discipline
# threshold-gate.sh uses).
headroom_slice="$(printf '%s' "$content" | python3 -c '
import re, sys
content = sys.stdin.read()
m = re.search(r"^#+[^\n]*(headroom|여유\s*용량|헤드룸)[^\n]*\n(.*?)(?=\n#+\s|\Z)", content, re.I | re.M | re.S)
sys.stdout.write(m.group(2) if m else content)
')"
cost_slice="$(printf '%s' "$content" | python3 -c '
import re, sys
content = sys.stdin.read()
m = re.search(r"^#+[^\n]*(cost note|cost|비용)[^\n]*\n(.*?)(?=\n#+\s|\Z)", content, re.I | re.M | re.S)
sys.stdout.write(m.group(2) if m else content)
')"

headroom_lc="$(printf '%s' "$headroom_slice" | tr '[:upper:]' '[:lower:]')"
cost_lc="$(printf '%s' "$cost_slice" | tr '[:upper:]' '[:lower:]')"
missing=""

# Band-not-snapshot: require a range token (a hyphenated/tilde number
# pair, or explicit "band"/"range"/대역/범위 language) somewhere near
# headroom language.
if printf '%s' "$headroom_lc" | grep -qE 'headroom|여유\s*용량|헤드룸'; then
  printf '%s' "$headroom_lc" | grep -qE '[0-9]+(\.[0-9]+)?[[:space:]]*(%|percent)?[[:space:]]*[-~][[:space:]]*[0-9]+(\.[0-9]+)?[[:space:]]*(%|percent)?|band|range|대역|범위' \
    || missing="${missing}- headroom stated as a snapshot number, not a band (Universal Scalability Law: margin degrades non-linearly near capacity)\n"
else
  missing="${missing}- no headroom figure found\n"
fi

# Cost-attributed-to-threshold: a cost note must name which threshold
# fired it, not just a bare figure.
if printf '%s' "$cost_lc" | grep -qE 'cost|비용'; then
  printf '%s' "$cost_lc" | grep -qE '(threshold|growth_rate|lead_time|safety_buffer|임계|기준).{0,120}(cost|비용)|(cost|비용).{0,120}(threshold|growth_rate|lead_time|safety_buffer|임계|기준)' \
    || missing="${missing}- cost note present but not attributed to a specific firing threshold\n"
else
  missing="${missing}- no cost note found\n"
fi

if [ -n "$missing" ]; then
  gate_deny "capacity-headroom-gate" "headroom/cost fields fail issue-1 norm (docs/issue-1/proposals/capacity-planning-methodology-norm.md; Universal Scalability Law):
$(printf '%b' "$missing")"
fi

gate_allow
