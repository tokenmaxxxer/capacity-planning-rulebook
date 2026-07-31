#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "directive.sh: fail-closed: aborted (rc=$rc)" >&2; exit 0; fi; }
trap __fc EXIT
# SessionStart addition — headroom/cost-note methodology framing.
# Not a second core_role_directive stub; print-only, always exits 0.
set -uo pipefail

cat <<'EOF'
[capacity-headroom-costnote] Headroom/cost-note framing (phase-2 record only):

- State headroom as a band, never a single snapshot number. The
  Universal Scalability Law (Gunther) models scaling as degrading
  non-linearly (contention and coherency cost) as a system approaches
  its capacity limit — only a band ("how much room, and how fast does
  that room shrink") communicates the actual risk.
- Attribute the incremental cost of the recommended expansion to the
  specific threshold that fires it, not as a free-floating figure.
- A mechanical backstop (hooks/headroom-gate.sh) checks the
  band-not-snapshot and cost-attribution requirements on write, but it
  is a heuristic, not a substitute for judgment.
EOF
