#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "directive.sh: fail-closed: aborted (rc=$rc)" >&2; exit 0; fi; }
trap __fc EXIT
# SessionStart addition — threshold-decomposition methodology framing.
# Not a second core_role_directive stub; print-only, always exits 0.
set -uo pipefail

cat <<'EOF'
[capacity-threshold-decomposition] Threshold-decomposition framing (phase-1 and phase-2):

- State the expansion-trigger threshold as
  growth_rate x lead_time x safety_buffer — never a bare flat
  percentage. Per Little's Law (L = λW, Little 1961): growth_rate is
  the arrival-rate term, lead_time is the wait term; their product,
  scaled by safety_buffer, is what determines unserved demand before
  expansion lands.
- Size the trigger to a stated percentile of demand (e.g. p97.5) over
  the forecast horizon.
- Label every term concretely — an untraceable/unlabeled figure fails
  this facet even if the formula shape is present.
- This facet spans both phases: proposal stage requires traceable
  numeric form, record stage requires the full decomposed structure for
  the same figures.
- A mechanical backstop (hooks/threshold-gate.sh) checks the
  labeled-term and percentile requirements on write, but it is a
  heuristic, not a substitute for judgment.
EOF
