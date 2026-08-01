#!/usr/bin/env bash
# capacity-order-enforcement: phase-1 proposal and phase-1 report
# (scout-brief) surfaces. Enforces the survey -> scout-brief -> proposal
# citation chain in lieu of a separate state file. survey.md itself is
# exempt (it is the root of the order).
# Kill switch: CAPACITY_ORDER_ENFORCEMENT_GATE_OFF=1
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh"
gate_trap_fail_closed
set -uo pipefail

gate_kill_switch_active "${CAPACITY_ORDER_ENFORCEMENT_GATE_OFF:-}" || { trap - EXIT; exit 0; }

input="$(cat)"

kind="$(printf '%s' "$input" | python3 -c '
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

root = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
tail = gate_lib.gate_normalize_path(root, fp)

k = "none"
if tail is not None:
    if re.match(r"^docs/issue-\d+/reports/capacity-planning/survey\.md$", tail):
        k = "survey-exempt"
    elif re.match(r"^docs/issue-\d+/reports/capacity-planning/scout-brief\.md$", tail):
        k = "scout-brief"
    elif re.match(r"^docs/issue-\d+/proposals/.*\.md$", tail):
        k = "proposal"
print(k)
')"
rc=$?
if [ "$rc" = 2 ]; then
  gate_deny "capacity-order-enforcement-gate" "malformed tool-call payload"
fi

if [ "$kind" = "none" ]; then
  gate_allow
fi

if [ "$kind" = "survey-exempt" ]; then
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
    deny("capacity-order-enforcement-gate: could not reconstruct resulting content (fail-closed)")
print(text)
')"
rc=$?
if [ "$rc" != 0 ]; then
  gate_deny "capacity-order-enforcement-gate" "could not reconstruct resulting content (fail-closed)"
fi

if [ "$kind" = "scout-brief" ]; then
  # scout-brief cites survey.md; non-terminal drafts (mid-write) exempt.
  if ! printf '%s' "$content" | grep -qiE 'loop_state:\s*terminal|state:\s*(done|terminal|complete)|^##[[:space:]]*sources'; then
    gate_allow
  fi

  adjacent="$(printf '%s' "$content" | python3 -c '
import re, sys
content = sys.stdin.read()
anchor = r"(basis:|sources:|^##.*rationale|^##.*sources)"
name = r"survey\.md"
ok = bool(re.search(anchor + r".{0,200}?" + name, content, re.I | re.M | re.S)) or \
     bool(re.search(name + r".{0,200}?" + anchor, content, re.I | re.M | re.S))
print("1" if ok else "0")
')"
  if [ "$adjacent" != "1" ]; then
    gate_deny "capacity-order-enforcement-gate" "scout-brief.md must cite survey.md adjacent to a Basis:/Sources: marker or a ##...Rationale/##...Sources heading (within ~200 chars), not just anywhere in the document"
  fi
  gate_allow
fi

# proposal: cite survey.md and scout-brief.md once terminal-looking.
if ! printf '%s' "$content" | grep -qiE 'loop_state:\s*terminal|state:\s*(done|terminal|complete)|^##[[:space:]]*rationale'; then
  gate_allow
fi

missing="$(printf '%s' "$content" | python3 -c '
import re, sys
content = sys.stdin.read()
anchor = r"(basis:|sources:|^##.*rationale|^##.*sources)"

def adjacent(name):
    return bool(re.search(anchor + r".{0,200}?" + name, content, re.I | re.M | re.S)) or \
           bool(re.search(name + r".{0,200}?" + anchor, content, re.I | re.M | re.S))

missing = []
if not adjacent(r"survey\.md"):
    missing.append("- proposal does not cite survey.md adjacent to a Basis:/Sources:/Rationale/Sources anchor")
if not adjacent(r"scout-brief\.md"):
    missing.append("- proposal does not cite scout-brief.md adjacent to a Basis:/Sources:/Rationale/Sources anchor")
print("\n".join(missing))
')"

if [ -n "$missing" ]; then
  gate_deny "capacity-order-enforcement-gate" "proposal fails document-sequencing precondition (citation must be adjacent to a Basis:/Sources: marker or a Rationale/Sources heading, within ~200 chars, not just anywhere in the document):
$missing"
fi

gate_allow
