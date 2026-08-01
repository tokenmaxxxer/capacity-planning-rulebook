#!/usr/bin/env bash
# capacity-threshold-decomposition: fires on both the phase-1 proposal
# surface (docs/issue-*/proposals/*.md) and the phase-2 record surface
# (docs/issue-*/reports/capacity-planning.md). Little's Law
# (growth_rate x lead_time x safety_buffer): traceable numeric form,
# percentile-stated, never a bare flat percentage.
# Kill switch: CAPACITY_THRESHOLD_GATE_OFF=1
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh"
gate_trap_fail_closed
set -uo pipefail

gate_kill_switch_active "${CAPACITY_THRESHOLD_GATE_OFF:-}" || { trap - EXIT; exit 0; }

input="$(cat)"

path_kind="$(printf '%s' "$input" | python3 -c '
import importlib.util, os, sys, re
_spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
gate_lib = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(gate_lib)

raw = sys.stdin.read()

def deny(msg):
    print(msg, file=sys.stderr)
    sys.exit(2)

d = gate_lib.gate_parse_json_or_deny(raw, deny)
ti = d.get("tool_input", {}) or {}
file_path = ti.get("file_path", "")
root = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
scope = gate_lib.gate_normalize_path(root, file_path)

kind = ""
if scope is not None:
    if re.match(r"^docs/issue-\d+/proposals/.*\.md$", scope):
        kind = "proposal"
    elif re.match(r"^docs/issue-\d+/reports/capacity-planning\.md$", scope):
        kind = "record"

print(file_path)
print(kind)
')"
rc=$?
[ $rc -ne 0 ] && gate_deny "capacity-threshold-gate" "unparseable payload"

file_path="$(printf '%s\n' "$path_kind" | sed -n '1p')"
kind="$(printf '%s\n' "$path_kind" | sed -n '2p')"

is_proposal=0
is_record=0
case "$kind" in
  proposal) is_proposal=1 ;;
  record) is_record=1 ;;
  *) gate_allow ;;
esac

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

try:
    with open(fp, "r", encoding="utf-8") as f:
        current = f.read()
except Exception:
    current = None

text, ok = gate_lib.gate_reconstruct_write(tool, ti, current)
if not ok:
    deny("could not reconstruct resulting content (fail-closed)")
print(text)
')"
rc=$?
[ $rc -ne 0 ] && gate_deny "capacity-threshold-gate" "could not reconstruct resulting content (fail-closed)"

# Non-terminal drafts are lenient on the record surface, matching this
# role's other phase-2 gates; the proposal surface has no such draft
# marker so it is checked on any terminal-looking content (a rationale
# section present, matching the forecast-method gate's heuristic).
if [ "$is_record" -eq 1 ]; then
  if ! printf '%s' "$content" | grep -qiE 'loop_state:\s*terminal|state:\s*(done|terminal|complete)'; then
    gate_allow
  fi
fi
if [ "$is_proposal" -eq 1 ]; then
  if ! printf '%s' "$content" | grep -qiE '^##[[:space:]]*rationale|loop_state:\s*terminal|state:\s*(done|terminal|complete)'; then
    gate_allow
  fi
fi

# Only enforce if the document actually talks about the threshold at
# all -- a document with no growth-rate/lead-time/threshold figures
# yet is not this plugin's concern.
if ! printf '%s' "$content" | grep -qiE 'growth_rate|lead_time|safety_buffer|성장률|리드타임|안전\s*버퍼|threshold'; then
  gate_allow
fi

# Scope the term/flat-percentage checks to the threshold-decomposition
# heading's slice rather than the whole document: on the record surface
# the heading is fixed ("Expansion trigger thresholds"); on the proposal
# surface, find the last "## ... threshold/임계 ..." heading and take from
# there to the next heading (or EOF). Fall back to the whole content if no
# such heading exists, so an undecomposed doc with no heading structure at
# all still gets checked rather than silently passing.
slice="$(printf '%s' "$content" | python3 -c '
import importlib.util, os, sys, re
_spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
gate_lib = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(gate_lib)

content = sys.stdin.read()
kind = sys.argv[1]

sliced = content

if kind == "record":
    m = re.search(r"^#+[^\n]*Expansion trigger thresholds[^\n]*\n(.*?)(?=\n#+\s|\Z)", content, re.I | re.M | re.S)
    if m:
        sliced = m.group(1)
else:
    headings = list(re.finditer(r"^##.*(?:threshold|임계).*$", content, re.I | re.M))
    if headings:
        rest = content[headings[-1].end():]
        nm = re.search(r"^#+\s", rest, re.M)
        sliced = rest[:nm.start()] if nm else rest

sys.stdout.write(sliced)
' "$kind")"

lc="$(printf '%s' "$slice" | tr '[:upper:]' '[:lower:]')"
missing=""

printf '%s' "$lc" | grep -qE 'growth_rate|성장률' || missing="${missing}- growth_rate term missing\n"
printf '%s' "$lc" | grep -qE 'lead_time|리드타임|조달\s*기간' || missing="${missing}- lead_time term missing\n"
printf '%s' "$lc" | grep -qE 'safety_buffer|안전\s*버퍼' || missing="${missing}- safety_buffer term missing\n"
printf '%s' "$lc" | grep -qE 'p[0-9]{1,3}(\.[0-9]+)?|percentile|백분위' || missing="${missing}- no percentile token (must be percentile-stated, not a bare figure)\n"

# Flat-percentage prohibition: a bare "NN%" with no percentile/labeling
# term nearby is rejected -- a lone percentage token unaccompanied by
# any percentile marker anywhere in the slice signals a flat-percentage
# threshold.
if printf '%s' "$lc" | grep -qE '[0-9]+(\.[0-9]+)?[[:space:]]*%' \
   && ! printf '%s' "$lc" | grep -qE 'p[0-9]{1,3}(\.[0-9]+)?|percentile|백분위'; then
  missing="${missing}- bare flat-percentage figure found with no percentile qualifier (forbidden by Little's Law decomposition)\n"
fi

if [ -n "$missing" ]; then
  gate_deny "capacity-threshold-gate" "$(printf 'threshold figures fail issue-1 norm (docs/issue-1/proposals/capacity-planning-methodology-norm.md; Little'"'"'s Law growth_rate x lead_time x safety_buffer):\n%b' "$missing")"
fi

gate_allow
