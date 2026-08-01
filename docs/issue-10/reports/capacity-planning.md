# Record — issue-10 (gate-house standard A+ remediation)

Subject: issue-10. Phase 2 execution of the approved proposal
([gate-house-standard-adoption.md](../proposals/gate-house-standard-adoption.md)),
approved via `APPROVE issue-10/capacity-planning` issue comment
(single-account mode, 2026-08-01).

## Why

The 2026-08-01 실물 코드 감사 (등급 C-) found this rulebook's five gates each
hand-rolled the same three defect shapes core's issue-72 audit found
repo-wide: a fail-closed EXIT trap that was unreachable dead code (malformed
JSON silently allowed, fail-open); a kill switch and `file_path` scope match
that only handled the relative-path glob case (absolute and `./`-prefixed
paths bypassed the gate); and an `Edit`/`MultiEdit` content reconstruction
that ignored `replace_all`. Core issue #72 landed the fix as a shared,
reference-only library (`core/hooks/lib/gate-lib.sh`/`gate-lib.py`,
`docs/handbooks/gate-house-standard.md`) before this issue's phase 2 could
start, per the issue's own stated precondition.

## What was done

**Item 1 — reference-adopt gate-lib in all five gates.** Each of
`capacity-fields-gate.sh`, `forecast-method-gate.sh`, `threshold-gate.sh`,
`headroom-gate.sh`, `citation-gate.sh` now sources
`gate-lib.sh` via `CLAUDE_PLUGIN_ROOT_CORE` (falling back to a
`../../core`-relative resolve), installs `gate_trap_fail_closed` before
`set -uo pipefail`, and calls `gate_kill_switch_active` for its kill switch
(fixed convention: only `1`/`true`/`yes`/`on` disables; every unset, empty,
recognized-off, or unrecognized value stays active — this is a real
behavior widening, not a no-op, since none of the five previously
recognized `true`/`yes`/`on` as on-spellings). Every embedded Python payload
loads `gate-lib.py` via the documented `importlib` pattern and calls
`gate_parse_json_or_deny` (malformed JSON now denies, closing the fail-open
hole in all five — three of the five previously exited 0 on bad JSON in
their file_path-extraction payload), `gate_normalize_path` (scope match
against the root-relative tail, covering absolute and `./`-prefixed paths
uniformly), and `gate_reconstruct_write` (full `Write`/`Edit`/`MultiEdit`
reconstruction honoring per-edit `replace_all`, denying fail-closed on an
unreconstructable call instead of the old NotebookEdit silent-passthrough
bug). All terminal exits now go through `gate_deny <name> <msg>` /
`gate_allow`.

**Item 2 — semantic checks upgraded to section/adjacency, not
whole-document substring.**

- `capacity-fields-gate.sh`: the four threshold-term checks
  (growth_rate/lead_time/safety_buffer/percentile) now run only against the
  text sliced from the "Expansion trigger thresholds" heading to the next
  heading, not the whole document — a term mention outside that subsection
  no longer satisfies the check.
- `threshold-gate.sh`: same heading-to-next-heading slice, scoped to
  "Expansion trigger thresholds" on the record surface or the nearest
  preceding `##...threshold/임계` heading on the proposal surface; the four
  term checks and the flat-percentage prohibition run against that slice.
- `citation-gate.sh`: `survey.md`/`scout-brief.md` citations must now occur
  within a `{0,200}`-char bounded window of a `Basis:`/`Sources:`/
  `##...Rationale`/`##...Sources` anchor (either order), not anywhere in the
  document — an unrelated "we are NOT citing X" aside no longer satisfies
  the check.
- `forecast-method-gate.sh`: the old whole-document `nonspace_len >= 200`
  proxy is replaced by an adjacency check — the method keyword (or
  `대안:`/`alternative:` marker) and the data-shape term must co-occur
  within `{0,300}` chars of each other, with `>= 40` non-whitespace chars of
  actual prose in the window between them.
- `headroom-gate.sh` is unchanged in item 2 — its existing bounded-window
  band/cost-attribution checks were already the precedent technique the
  other four gates are being upgraded to match.

**Item 3 — mandatory test cases, full green suite.** `tests/run-gate-tests.sh`
gained: `capacity-fields-gate.sh`'s first-ever coverage group (six cases:
non-terminal leniency, each of the three missing-heading denials, a
missing-term denial, and the all-fields-present allow); the six
house-standard-mandatory case groups applied across the five gates —
`MultiEdit` with mixed `replace_all` true/false (1 case, proves the
reconstruction honors per-edit flags), malformed JSON denies (15 cases,
3 payload shapes × 5 gates), kill-switch-set-to-an-unrecognized-value stays
active (5 cases, one per gate), absolute/`./`-prefixed path treated
identically to the relative fixture (3 cases), and a `Bash`-tool file write
reaching the same target a `Write` call would hit (1 case — see "Open
findings" below for why this one is recorded as an expected allow, not a
deny). Full suite: **53 passed, 0 failed** (verbatim run below).

**Item 4 — README realignment.** `README.md`'s Layout section no longer
lists the three ghost entries (`record-fields-gate.sh`, `trailer-gate.sh`,
`handbook-trigger-gate.sh`, deleted by issue-2, never restored); it now
states plainly that trailer/record-fields/handbook-trigger enforcement
comes from core's `core/hooks/hooks.json` firing globally keyed off
`CLAUDE_ROLE=capacity-planning`. Added a `capacity-fields-gate.sh` Layout
line (present but previously undocumented) and a new "Gate-house standard"
subsection pointing at `docs/handbooks/gate-house-standard.md` and this
record.

## Compliance-detector evidence

`core/hooks/tests/compliance-check.sh`, run against this rulebook's five
gate files, before item 1 landed (git `HEAD` at the start of this phase) and
after:

```
$ compliance-check.sh <baseline: HEAD copies of the five gate files>
compliance-check: FAIL — capacity-order-enforcement/hooks/citation-gate.sh:
  - reads a *_OFF kill-switch env var but does not call gate_kill_switch_active — likely a hand-rolled case statement with the confirmed fail-open bug (unrecognized value disables the gate)
  - reconstructs Edit/MultiEdit content via its own .replace(...) call instead of gate_lib.gate_reconstruct_write — likely ignores replace_all
compliance-check: FAIL — capacity-threshold-decomposition/hooks/threshold-gate.sh:
  - reads a *_OFF kill-switch env var but does not call gate_kill_switch_active — likely a hand-rolled case statement with the confirmed fail-open bug (unrecognized value disables the gate)
  - reconstructs Edit/MultiEdit content via its own .replace(...) call instead of gate_lib.gate_reconstruct_write — likely ignores replace_all
compliance-check: FAIL — capacity-headroom-costnote/hooks/headroom-gate.sh:
  - reads a *_OFF kill-switch env var but does not call gate_kill_switch_active — likely a hand-rolled case statement with the confirmed fail-open bug (unrecognized value disables the gate)
  - reconstructs Edit/MultiEdit content via its own .replace(...) call instead of gate_lib.gate_reconstruct_write — likely ignores replace_all
compliance-check: FAIL — capacity-forecast-method/hooks/forecast-method-gate.sh:
  - reads a *_OFF kill-switch env var but does not call gate_kill_switch_active — likely a hand-rolled case statement with the confirmed fail-open bug (unrecognized value disables the gate)
  - reconstructs Edit/MultiEdit content via its own .replace(...) call instead of gate_lib.gate_reconstruct_write — likely ignores replace_all
compliance-check: FAIL — capacity-planning/hooks/capacity-fields-gate.sh:
  - reads a *_OFF kill-switch env var but does not call gate_kill_switch_active — likely a hand-rolled case statement with the confirmed fail-open bug (unrecognized value disables the gate)
  - reconstructs Edit/MultiEdit content via its own .replace(...) call instead of gate_lib.gate_reconstruct_write — likely ignores replace_all
(exit 1 — 5/5 flagged, as expected given the audit's findings)

$ compliance-check.sh <this repo, post-migration>
compliance-check: ok — capacity-order-enforcement/hooks/citation-gate.sh
compliance-check: ok — capacity-threshold-decomposition/hooks/threshold-gate.sh
compliance-check: ok — capacity-headroom-costnote/hooks/headroom-gate.sh
compliance-check: ok — capacity-forecast-method/hooks/forecast-method-gate.sh
compliance-check: ok — capacity-planning/hooks/capacity-fields-gate.sh
(exit 0 — 5/5 clean)
```

## Full gate-test suite (verbatim, post-migration)

```
== capacity-forecast-method ==
ok     non-terminal-draft                     allow
ok     no-method-fail                         deny
ok     keyword-no-justification               deny
ok     justification-no-shape-link            deny
ok     method-named-with-shape-link           allow
ok     foreign-path                           allow
== capacity-threshold-decomposition ==
ok     no-threshold-mentioned                 allow
ok     flat-percentage-fail                   deny
ok     missing-percentile                     deny
ok     labeled-with-percentile                allow
ok     foreign-path                           allow
== capacity-headroom-costnote ==
ok     non-terminal-record                    allow
ok     snapshot-headroom-fail                 deny
ok     cost-not-attributed                    deny
ok     band-and-attributed-cost               allow
ok     foreign-path                           allow
== capacity-order-enforcement ==
ok     non-terminal-proposal                  allow
ok     proposal-missing-citations             deny
ok     proposal-with-citations                allow
ok     scout-brief-missing-survey             deny
ok     scout-brief-with-survey                allow
ok     survey-exempt                          allow
== capacity-fields-gate (first coverage, issue-10) ==
ok     non-terminal-lenient                   allow
ok     missing-forecast-heading               deny
ok     missing-thresholds-heading              deny
ok     missing-growth-rate-term               deny
ok     all-fields-present                     allow
ok     foreign-path                           allow
== mandatory case group: replace_all Edit / MultiEdit reconstruction ==
ok     multiedit-replace_all-mixed            allow
== mandatory case group: malformed JSON denies (fail-closed) ==
ok     forecast-method-gate.sh: truncated JSON denies deny
ok     forecast-method-gate.sh: non-object JSON denies deny
ok     forecast-method-gate.sh: empty payload denies deny
ok     threshold-gate.sh: truncated JSON denies deny
ok     threshold-gate.sh: non-object JSON denies deny
ok     threshold-gate.sh: empty payload denies deny
ok     headroom-gate.sh: truncated JSON denies deny
ok     headroom-gate.sh: non-object JSON denies deny
ok     headroom-gate.sh: empty payload denies deny
ok     citation-gate.sh: truncated JSON denies deny
ok     citation-gate.sh: non-object JSON denies deny
ok     citation-gate.sh: empty payload denies deny
ok     capacity-fields-gate.sh: truncated JSON denies deny
ok     capacity-fields-gate.sh: non-object JSON denies deny
ok     capacity-fields-gate.sh: empty payload denies deny
== mandatory case group: kill switch unrecognized value stays active ==
ok     forecast-method: OFF=banana stays active deny
ok     threshold: OFF=banana stays active     deny
ok     headroom: OFF=banana stays active      deny
ok     order-enforcement: OFF=banana stays active deny
ok     fields: OFF=banana stays active        deny
== mandatory case group: absolute path / ./-prefixed path treated same as relative ==
ok     threshold-abs-path                     deny
ok     threshold-dotslash-path                deny
ok     order-enforcement-abs-survey-exempt    allow
== mandatory case group: Bash-tool write reaches the same target as a Write call ==
ok     threshold-bash-write-not-yet-covered   allow

pass=53 fail=0
```

## What was NOT done

- No canon script vendored — every gate references `gate-lib.sh`/
  `gate-lib.py` via `CLAUDE_PLUGIN_ROOT_CORE`; no copy exists anywhere in
  this repo (`docs/handbooks/canon-scripts.md`'s rule).
- The domain semantics of what each gate checks for (growth_rate/
  lead_time/safety_buffer/percentile decomposition, headroom-as-band,
  citation chain, forecast-method selection) are unchanged — this issue
  is a structural/mechanical remediation of *how* those checks are
  implemented and tested, not a re-litigation of *what* they require.
- `capacity-planning/hooks/directive.sh`, `hooks.json` wiring shape, and
  every plugin's `.claude-plugin/plugin.json` — untouched.

## Upstream basis

- Issue: #10.
- Approved proposal:
  [gate-house-standard-adoption.md](../proposals/gate-house-standard-adoption.md).
- Survey: [survey.md](capacity-planning/survey.md).
- Scout brief: [scout-brief.md](capacity-planning/scout-brief.md) (scouting
  skipped — spec fully fixed by core issue #72; see the brief for the skip
  record).
- Precondition: core issue #72
  (`docs/handbooks/gate-house-standard.md`, PR #74, merged
  2026-08-01T06:55:01Z).

## Open findings

- **`gate_bash_write_targets` not yet adopted by any of this rulebook's
  five gates.** The mandatory Bash-write-coverage test case is recorded
  above as an expected *allow* (the gate does not fire), not a deny,
  because none of the five gates currently matches `tool_name == "Bash"` —
  they only match `Write`/`Edit`/`MultiEdit`/`NotebookEdit`
  `tool_input.file_path`. A `Bash`-tool redirect (`cat > <in-scope-path>`)
  therefore bypasses all five gates today. This is a real, currently
  uncovered gap surfaced (not silently omitted) by this migration, not
  closed by it — the issue-10 proposal's item 1 did not include wiring
  `gate_bash_write_targets` into the five gates' own scope-match payloads,
  only migrating the checks that already existed. The test case is a
  regression fixture: adopting `gate_bash_write_targets` in a follow-up
  should flip this case's expectation from allow to deny.
- Same heuristic-quality caveat issue-7's record already carries forward:
  the threshold/headroom/citation adjacency windows are regex-shaped
  proximity checks, not a parse of the actual proposed field grammar — a
  determined bad-faith writer could still satisfy the pattern without
  satisfying the methodology's intent. The house-standard's own framing
  ("a heuristic, not a substitute for judgment") applies here as before.

## Next steps

- If a Bash-tool write to an in-scope path is ever observed reaching one
  of these five gates' targets undetected in practice (not just in the
  test fixture), file a follow-up issue to wire `gate_bash_write_targets`
  into each gate's scope-match payload — same resolution-path shape as
  issue-7's own open findings (observation-driven, not a speculative
  rewrite now).
- Re-run `compliance-check.sh` against this rulebook whenever a sixth gate
  is added, so it stays clean by construction rather than by one-time
  migration.

loop_state: landed
