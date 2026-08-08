---
code_under_review: README.md, capacity-planning/hooks/capacity-fields-gate.sh, capacity-planning/hooks/directive.sh, docs/handbooks/capacity-planning/forecast-checklist.md, tests/run-gate-tests.sh
type: coding-record
breaking: false
verdict: within-scope
loop_state: landed
kind: coding-record
---

# Record — issue-16 (align rulebook with realized capacity-planning spec)

Subject: issue-16. Phase 2 execution of the approved proposal
([spec-field-alignment.md](../proposals/spec-field-alignment.md)),
approved via `APPROVE issue-16/implementation` issue comment
(single-account mode, `docs/specs/approvers.md`-listed account
`JiwonJung94`). Basis: docs/issue-16/proposals/spec-field-alignment.md,
docs/issue-16/reports/implementation/survey.md,
docs/issue-16/reports/implementation/scout-brief.md.

## What was done

1. `docs/handbooks/capacity-planning/forecast-checklist.md`: added step
   0 (state the `resource` this record is about) and step 6 (render a
   `verdict`, recomputed from `demand_forecast` against
   `capacity_threshold`); cross-referenced `demand_forecast` on step 1
   and `capacity_threshold` on step 4 so `grep -ri` finds the spec
   field names.
2. `capacity-planning/hooks/capacity-fields-gate.sh`: added a
   "Resource" required-heading check (same pattern as the existing
   three) and a "Verdict" required-heading check whose heading slice
   must additionally contain `within-capacity` or `over-capacity`
   (mirrors the existing threshold-slice-check pattern).
3. `capacity-planning/hooks/directive.sh`: extended the `PRODUCES`
   string with `resource` and `verdict` field descriptions.
4. `README.md`: extended the `produces:` line with `resource` and
   `verdict`; added a "Marketplace spec alignment (issue-16)"
   subsection with a field-mapping table (all four spec required
   fields → rulebook home) and the `loop_state` vocabulary mapping
   (`forecasting`/`reviewing` in-progress, `threshold-undeclared`
   refusal, `resource-unreachable` error, `landed` the sole terminal
   state via self-declared `kind: coding-record` frontmatter).
5. `tests/run-gate-tests.sh`: added allow/deny cases for the new
   Resource/Verdict heading checks (missing-resource-heading,
   missing-verdict-heading, verdict-missing-determination) and updated
   the existing allow-path fixtures (GOOD_CF, multiedit, edit cases) to
   carry Resource/Verdict headings so they still exercise only their
   original claim.
6. `capacity-planning/hooks/capacity-fields-gate.sh` (leniency check):
   the before-landing warrant hunt (see `## Open findings`) found the
   gate's terminal-write trigger regex matched literal
   `loop_state: terminal` only, never `loop_state: landed` — the
   actual terminal value this role's records (and this README's own
   new spec-alignment subsection) document. A record landed with
   `loop_state: landed` and missing headings would silently pass every
   one of the five required-heading checks (the pre-existing three
   and the two new ones). Fixed the regex to match `terminal|landed`;
   added regression case `missing-resource-heading-loop-state-landed`.
7. `docs/specs/record-fields-terminal-states.json` — NOT created. The
   proposal's own conditional (What will be done, item 6) authorized
   dropping it from the write set if a same-as-core-default entry adds
   no value beyond documenting the choice in README.md; confirmed by
   reading core's `record-fields-gate.sh` directly
   (`KIND_TERMINAL_DEFAULTS["coding-record"] == {"landed"}`, and the
   `ROLE_TO_KIND`-fallback path consults a record's own `kind:` field) —
   the README subsection above documents the choice and no gate
   behavior needs a role-specific override file.

## What did not work

None.

## Rationale for deviations

None — item 6 above (dropping `record-fields-terminal-states.json`) is
not a deviation; it executes the proposal's own explicitly pre-approved
conditional ("If phase-2 finds writing a same-as-default entry adds no
value... this will be stated in the phase-2 record either way").

## Verification run

`bash tests/run-gate-tests.sh` — `pass=72 fail=0`, including the three
new Resource/Verdict cases, the two updated allow-path fixtures, and
the `loop_state: landed` leniency-regression case added after the
before-landing hunt finding.

`grep -ril "resource\|demand_forecast\|capacity_threshold\|verdict" docs/ README.md`
matches README.md and the checklist (plus prior-issue records, unaffected).
`grep -ril "forecasting\|landed\|resource-unreachable\|reviewing\|threshold-undeclared" README.md`
matches README.md.

## Upstream basis

- Issue: #16.
- Approved proposal: [spec-field-alignment.md](../proposals/spec-field-alignment.md).
- Survey: [survey.md](implementation/survey.md).
- Spec: `roles/specs/capacity-planning.spec.json` (on-the-record).

## Open findings

None remaining. The after-proposal warrant hunt
(docs/reports/2026-08-09-hunt-spec-field-alignment.md) recorded no
finding on the frozen write set. The before-landing hunt (same file,
appended section, stance "assume this change and another plugin's rule
cancel each other") found one real gap:
`capacity-fields-gate.sh`'s leniency check fired only on
`loop_state: terminal`, never the actually-documented terminal value
`loop_state: landed`, so none of the five required-heading checks
(including this issue's two new ones) would ever run against a
record using this role's real terminal state. Resolved in this same
commit (see `## What was done` item 6) and re-cleared by re-running
the full gate test suite (`pass=72 fail=0`, including the new
`missing-resource-heading-loop-state-landed` regression case).

## resolved_findings

- source: docs/reports/2026-08-09-hunt-spec-field-alignment.md
  (before-landing section, stance 1)
  finding: capacity-fields-gate.sh leniency regex never matches
  `loop_state: landed`
  resolution: regex widened to `terminal|landed`; regression test
  added; full suite re-run green.
  code_under_review: 436dc05d901cedb157aab86ca467f915d62287f6

## closed_checks

- gate-test-suite-pass: ref: tests/run-gate-tests.sh:1
- acceptance-grep-fields: ref: README.md:9
- acceptance-grep-loop-state: ref: README.md:100
- landed-leniency-regression: ref: tests/run-gate-tests.sh:170
