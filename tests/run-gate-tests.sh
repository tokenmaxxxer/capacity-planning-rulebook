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

echo
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
