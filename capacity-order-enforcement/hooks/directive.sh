#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "directive.sh: fail-closed: aborted (rc=$rc)" >&2; exit 0; fi; }
trap __fc EXIT
# SessionStart addition — order-enforcement (citation-presence)
# framing. Not a second core_role_directive stub; this plugin does not
# own a role, it owns a single cross-cutting discipline. Print-only,
# always exits 0.
set -uo pipefail

cat <<'EOF'
[capacity-order-enforcement] Document-sequencing / citation-presence framing (phase-1 only):

- survey.md grounds scout-brief.md, and both ground the proposal. Each
  later document cites its predecessors by filename once it reaches a
  terminal-looking section — this is the ordering mechanism in place of
  a separate state file.
- This precondition runs conceptually before the other phase-1 plugins'
  content checks (capacity-forecast-method,
  capacity-threshold-decomposition): a proposal or scout-brief with no
  citation of its predecessor has not established it is grounded in the
  correct evidence chain, so those checks are not meaningful yet.
- survey.md itself is exempt — it is the root of the order and has no
  predecessor to cite.
- A mechanical backstop (hooks/citation-gate.sh) checks filename
  citation on write, but it is a heuristic, not a substitute for
  review.
EOF
