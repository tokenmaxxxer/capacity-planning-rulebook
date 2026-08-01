#!/usr/bin/env bash
# capacity-planning plugin-set gate tests. Follows the
# implementation-rulebook/pricing-rulebook/security-threat-model
# harness convention: temp git repo per case, JSON PreToolUse payload
# piped via stdin, exit-code assertion (0=allow, 2=deny).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT="$HERE/.."
pass=0; fail=0
report() { if [ "$2" = "$1" ]; then pass=$((pass+1)); printf 'ok     %-38s %s\n' "$3" "$2"; else fail=$((fail+1)); printf 'FAIL   %-38s want=%s got=%s\n' "$3" "$1" "$2"; fi; }

# run want name gate_script rel_path content
run() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
    "$4" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$5")" "$td" \
    | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$3" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report "$1" "$got" "$2"
}

PROPOSAL=docs/issue-7/proposals/enforcement-machinery-deepening.md
RECORD=docs/issue-7/reports/capacity-planning.md
SCOUT=docs/issue-7/reports/capacity-planning/scout-brief.md

SHAPE_LINK="organic growth"
JUSTIFY_PAD="This method is justified by the observed steady demand curve over the past twelve months, which shows no scenario-driven spikes and a stable week-over-week growth pattern with no single scheduled event driving it."

echo "== capacity-forecast-method =="
FM="$ROOT/capacity-forecast-method/hooks/forecast-method-gate.sh"
run allow non-terminal-draft "$FM" "$PROPOSAL" "## Draft
still writing, no method yet"
run deny  no-method-fail "$FM" "$PROPOSAL" "## Rationale
we will figure out the technique later. ${JUSTIFY_PAD} organic"
run deny  keyword-no-justification "$FM" "$PROPOSAL" "## Rationale
regression organic"
run deny  justification-no-shape-link "$FM" "$PROPOSAL" "## Rationale
regression trend fit. ${JUSTIFY_PAD}"
run allow method-named-with-shape-link "$FM" "$PROPOSAL" "## Rationale
We pick linear regression trend fit. ${JUSTIFY_PAD} data shape: ${SHAPE_LINK}."
run allow foreign-path "$FM" "docs/issue-7/reports/qa.md" "## Rationale
anything"

echo "== capacity-threshold-decomposition =="
TH="$ROOT/capacity-threshold-decomposition/hooks/threshold-gate.sh"
run allow no-threshold-mentioned "$TH" "$PROPOSAL" "## Rationale
this document does not discuss expansion sizing at all"
run deny  flat-percentage-fail "$TH" "$RECORD" "state: terminal
## Expansion trigger thresholds
we expand at 80% utilization, growth_rate 12%, lead_time 2 weeks, safety_buffer 10%"
run deny  missing-percentile "$TH" "$RECORD" "state: terminal
## Expansion trigger thresholds
growth_rate 12%/mo, lead_time 2 weeks, safety_buffer 15%"
run allow labeled-with-percentile "$TH" "$RECORD" "state: terminal
## Expansion trigger thresholds
growth_rate 12%/mo, lead_time 2 weeks, safety_buffer 15%, sized to p97.5 of demand over the forecast horizon"
run allow foreign-path "$TH" "docs/issue-7/reports/qa.md" "growth_rate 12%"

echo "== capacity-headroom-costnote =="
HR="$ROOT/capacity-headroom-costnote/hooks/headroom-gate.sh"
run allow non-terminal-record "$HR" "$RECORD" "## Cost note
still drafting"
run deny  snapshot-headroom-fail "$HR" "$RECORD" "state: terminal
## Headroom
headroom is 22%
## Cost note
cost: \$4,000/mo attributed to the safety_buffer threshold"
run deny  cost-not-attributed "$HR" "$RECORD" "state: terminal
## Headroom
headroom band 18%-24%
## Cost note
cost: \$4,000/mo"
run allow band-and-attributed-cost "$HR" "$RECORD" "state: terminal
## Headroom
headroom band 18%-24%
## Cost note
cost: \$4,000/mo attributed to the growth_rate threshold firing"
run allow foreign-path "$HR" "$PROPOSAL" "headroom 22%"

echo "== capacity-order-enforcement =="
OE="$ROOT/capacity-order-enforcement/hooks/citation-gate.sh"
run allow non-terminal-proposal "$OE" "$PROPOSAL" "## Draft
still writing"
run deny  proposal-missing-citations "$OE" "$PROPOSAL" "## Rationale
no citations here"
run allow proposal-with-citations "$OE" "$PROPOSAL" "## Rationale
Basis: survey.md, scout-brief.md"
run deny  scout-brief-missing-survey "$OE" "$SCOUT" "## Sources
no survey cited"
run allow scout-brief-with-survey "$OE" "$SCOUT" "## Sources
survey.md"
run allow survey-exempt "$OE" "docs/issue-7/reports/capacity-planning/survey.md" "## Sources
nothing to cite"

echo "== capacity-fields-gate (first coverage, issue-10) =="
CF="$ROOT/capacity-planning/hooks/capacity-fields-gate.sh"
CFPATH=docs/issue-7/reports/capacity-planning.md
GOOD_CF="state: terminal
## Capacity forecast
x
## Expansion trigger thresholds
growth_rate 12%/mo, lead_time 2 weeks, safety_buffer 15%, sized to p97.5
## Cost note
x"
run allow non-terminal-lenient "$CF" "$CFPATH" "## Capacity forecast
still drafting"
run deny  missing-forecast-heading "$CF" "$CFPATH" "state: terminal
## Expansion trigger thresholds
growth_rate 12%/mo, lead_time 2 weeks, safety_buffer 15%, p97.5
## Cost note
x"
run deny  missing-thresholds-heading "$CF" "$CFPATH" "state: terminal
## Capacity forecast
x
## Cost note
x"
run deny  missing-growth-rate-term "$CF" "$CFPATH" "state: terminal
## Capacity forecast
x
## Expansion trigger thresholds
lead_time 2 weeks, safety_buffer 15%, p97.5
## Cost note
x"
run allow all-fields-present "$CF" "$CFPATH" "$GOOD_CF"
run allow foreign-path "$CF" "docs/issue-7/reports/qa.md" "state: terminal
anything"

echo "== mandatory case group: replace_all Edit / MultiEdit reconstruction =="
runedit() { # want name gate_script rel_path existing_content payload_json
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
  mkdir -p "$(dirname "$td/$4")"
  printf '%s' "$5" > "$td/$4"
  out="$(cd "$td" && printf '%s' "$6" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$3" 2>&1)"
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report "$1" "$got" "$2"
}
GOOD_CF_MULTI='{"tool_name":"MultiEdit","tool_input":{"file_path":"'"$CFPATH"'","edits":[{"old_string":"PLACEHOLDER","new_string":"growth_rate 12%/mo, lead_time 2 weeks, safety_buffer 15%, p97.5","replace_all":true},{"old_string":"still drafting","new_string":"y","replace_all":false}]}}'
runedit allow multiedit-replace_all-mixed "$CF" "$CFPATH" "state: terminal
## Capacity forecast
PLACEHOLDER
## Expansion trigger thresholds
PLACEHOLDER
## Cost note
still drafting" "$GOOD_CF_MULTI"

echo "== mandatory case group: malformed JSON denies (fail-closed) =="
malformed() { # gate_script raw_payload name
  out="$(printf '%s' "$2" | env CLAUDE_PROJECT_DIR="$(mktemp -d)" /bin/bash "$1" 2>&1)"
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  report deny "$got" "$(basename "$1"): $3"
}
for g in "$FM" "$TH" "$HR" "$OE" "$CF"; do
  malformed "$g" '{"tool_name":"Write"' "truncated JSON denies"
  malformed "$g" '"just a string"' "non-object JSON denies"
  malformed "$g" '' "empty payload denies"
done

echo "== mandatory case group: kill switch unrecognized value stays active =="
ksw() { # gate_script varname name file content want
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
  payload="$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s}}' "$4" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$5")")"
  out="$(printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" "${2}=banana" /bin/bash "$1" 2>&1)"
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report "$6" "$got" "$3"
}
ksw "$FM" CAPACITY_FORECAST_METHOD_GATE_OFF "forecast-method: OFF=banana stays active" "$PROPOSAL" "## Rationale
no method here at all" deny
ksw "$TH" CAPACITY_THRESHOLD_GATE_OFF "threshold: OFF=banana stays active" "$RECORD" "state: terminal
## Expansion trigger thresholds
we expand at 80% utilization" deny
ksw "$HR" CAPACITY_HEADROOM_GATE_OFF "headroom: OFF=banana stays active" "$RECORD" "state: terminal
## Headroom
headroom is 22%
## Cost note
cost: \$1" deny
ksw "$OE" CAPACITY_ORDER_ENFORCEMENT_GATE_OFF "order-enforcement: OFF=banana stays active" "$PROPOSAL" "## Rationale
no citations here" deny
ksw "$CF" CAPACITY_FIELDS_GATE_OFF "fields: OFF=banana stays active" "$CFPATH" "state: terminal
## Capacity forecast
x" deny

echo "== mandatory case group: absolute path / ./-prefixed path treated same as relative =="
runroot() { # want gate_script root file_path content name
  payload="$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s}}' \
    "$4" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$5")")"
  out="$(printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$3" /bin/bash "$2" >/dev/null 2>&1)"
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  report "$1" "$got" "$6"
}
DENYCONTENT="state: terminal
## Expansion trigger thresholds
we expand at 80% utilization"
td_abs="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td_abs"
runroot deny "$TH" "$td_abs" "$td_abs/$RECORD" "$DENYCONTENT" "threshold-abs-path"
runroot deny "$TH" "$td_abs" "./$RECORD" "$DENYCONTENT" "threshold-dotslash-path"
rm -rf "$td_abs"
td_ex="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td_ex"
mkdir -p "$td_ex/docs/issue-7/reports/capacity-planning"
runroot allow "$OE" "$td_ex" "$td_ex/docs/issue-7/reports/capacity-planning/survey.md" "anything at all" "order-enforcement-abs-survey-exempt"
rm -rf "$td_ex"

echo "== mandatory case group: Bash-tool write reaches the same target as a Write call =="
bashwrite() { # want name gate_script rel_path command
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
  payload="$(printf '{"tool_name":"Bash","tool_input":{"command":%s},"cwd":"%s"}' \
    "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$5")" "$td")"
  out="$(printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$3" >/dev/null 2>&1)"
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report "$1" "$got" "$2"
}
# None of these five gates match tool_name=="Bash" today (they only fire on
# Write/Edit/MultiEdit/NotebookEdit tool_input.file_path); a Bash-tool write
# to the same in-scope target is therefore not intercepted by any of them.
# This is a real, currently-uncovered gap this mandatory case group exists to
# surface: recorded here as an expected allow (gate does not fire) rather
# than silently omitted, so a future gate_bash_write_targets adoption has a
# regression test to flip to deny.
bashwrite allow threshold-bash-write-not-yet-covered "$TH" "$RECORD" \
  "cat > $RECORD <<'EOF'
we expand at 80% utilization
EOF"

echo
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
