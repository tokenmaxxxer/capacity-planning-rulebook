#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "directive.sh: fail-closed: aborted (rc=$rc)" >&2; exit 0; fi; }
trap __fc EXIT
# SessionStart addition — forecast-method methodology framing. Not a
# second core_role_directive stub (that positional call stays solely in
# the base capacity-planning plugin); this only prints phase-1 framing
# text so it shows up in session context. Non-blocking: a print, not a
# gate, so it always exits 0 on a normal run.
set -uo pipefail

cat <<'EOF'
[capacity-forecast-method] Forecast-method selection framing (phase-1 proposal only):

- Classify the workload's demand shape first: steady/organic growth, a
  specific scenario/inorganic event, or seasonality/campaign-driven —
  with the evidence (time series, event calendar, campaign schedule)
  behind the classification. Per SRE book "Capacity Planning" chapter.
- Pick the method the shape calls for: linear/exponential regression
  trend fit (steady organic growth); Holt-Winters exponential smoothing
  or ARIMA (seasonality/campaign-driven demand); scenario/queueing
  modeling (a specific inorganic event) — or an explicitly justified
  alternative under a literal `대안:`/`alternative:` marker.
- State the pick with substantive justification tied to the shape
  classification, not a bare keyword.
- If a prior forecast exists for the same subject, compare
  forecast-vs-actual: a divergence is a model-instability signal to
  flag, never silently overwrite.
- A mechanical backstop (hooks/forecast-method-gate.sh) checks the
  keyword/justification/shape-link on write, but it is a heuristic, not
  a substitute for judgment.
EOF
