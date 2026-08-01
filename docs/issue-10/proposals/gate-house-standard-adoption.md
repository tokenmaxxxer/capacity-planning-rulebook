# Proposal — adopt the gate-house standard to close issue-10's audit findings (A+)

Subject: issue-10. Phase 1 only: this document is the plan; no execution
happens until Approve. Basis: [survey.md](../reports/capacity-planning/survey.md),
[scout-brief.md](../reports/capacity-planning/scout-brief.md) (scouting
skipped — spec fully fixed by core issue #72, no design decision left
open).

forecast-method: 해당 없음 — this proposal is a gate-conformance
remediation, not a capacity-forecast-method deliverable; the forecast
method gate's own explicit not-applicable carve-out applies.

## Ordering and scope

Precondition satisfied: core issue #72 landed
(`core/hooks/lib/gate-lib.sh`, `core/hooks/lib/gate-lib.py`,
`docs/handbooks/gate-house-standard.md`, PR #74 merged
2026-08-01T06:55:01Z). Every item below sources/imports that canon by
reference (`docs/handbooks/canon-scripts.md`'s rule) — none of it is
reimplemented locally. Phase 2 executes the four numbered requirements
from the issue body in the order below; this proposal covers all four,
plus the core-reference precondition and the mandatory test cases.

## Item 1 — reference-adopt `gate-lib.sh`/`gate-lib.py` in all five gates

Each of `capacity-fields-gate.sh`, `forecast-method-gate.sh`,
`threshold-gate.sh`, `headroom-gate.sh`, `citation-gate.sh` gets the same
four mechanical replacements, closing survey.md's Findings 1-3:

1. **Trap-at-top fail-closed.** First line after the shebang/comment
   header becomes:
   ```
   . "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh"
   gate_trap_fail_closed
   set -uo pipefail
   ```
   installed *before* the kill-switch check, so a syntax error or an
   `set -u` unset-variable abort later in the script is remapped to
   `exit 2` instead of silently falling through to the shell's default
   fail-open behavior. This directly answers survey.md Finding 1
   ("fail-closed가 도달 불능 데드 코드").
2. **Kill switch via `gate_kill_switch_active`.** Replace each gate's own
   `[ "${X_GATE_OFF:-0}" = "1" ] && exit 0` line with
   `gate_kill_switch_active "${X_GATE_OFF:-}" || { trap - EXIT; exit 0; }`.
   Net behavior change, not a no-op: today only the literal string `1`
   disables a gate (arguably fail-closed-leaning by accident), but none of
   the five recognize `true`/`yes`/`on` as on-spellings the way the house
   standard's kill-switch convention requires, so this is a real widening
   of the operator-facing kill-switch contract to the documented
   recognized-on-spellings set, not free-floating scope creep — it is the
   contract `gate-house-standard.md` names as the fixed convention every
   downstream gate must match.
3. **`gate_parse_json_or_deny` for the JSON payload.** Both the
   `file_path`-extraction and content-reconstruction Python payloads in
   each gate currently `try/except: sys.exit(0)`/`sys.exit(1)` around
   `json.load` (survey.md Finding 1's dead fail-closed code). Replace with
   a single `gate_lib.gate_parse_json_or_deny(raw, deny)` call per Python
   payload (loaded via the `importlib`/`GATE_LIB_PY` pattern
   `gate-house-standard.md` documents), where `deny` is a small local
   closure that prints to stderr and calls `sys.exit(2)` — so malformed
   JSON now actually reaches an `exit 2` from the gate process, closing
   the fail-open hole.
4. **`gate_normalize_path` for the `file_path` match, `gate_reconstruct_write`
   for Write/Edit/MultiEdit/NotebookEdit.** Replace each gate's own `case
   "$file_path" in .../docs/...) ;; *) exit 0 ;; esac` glob pair with a
   Python-side `gate_lib.gate_normalize_path(root, file_path)` call
   (root = the gate's own repo root, resolved once via
   `os.environ.get("CLAUDE_PROJECT_DIR", ...)` the same way each gate's
   existing content-reconstruction payload already resolves `fp`), then
   apply the gate's own scope pattern (e.g. `^docs/issue-\d+/proposals/`)
   to the returned root-relative tail instead of the tail-glob. This
   covers absolute paths and `./`-prefixed paths uniformly by construction
   instead of by five independently-hoped-correct glob strings (survey.md
   Finding 2). Replace each gate's own inline Write/Edit/MultiEdit
   reconstruction block with one `gate_lib.gate_reconstruct_write(tool,
   tool_input, current_content)` call; a `(None, False)` return denies
   rather than falling through to `read_existing()` (today's silent
   NotebookEdit passthrough bug, survey.md Finding 3).
5. **`gate_deny`/`gate_allow` for the terminal exit.** Every `echo ... >&2;
   exit 2` / bare `exit 0` at each gate's end becomes
   `gate_deny "<gate-name>" "<message>"` / `gate_allow`, codifying the
   stderr-only protocol the standard already found uniform in this repo
   (no change in observable behavior; consistency with the shared idiom).

`capacity-planning/hooks/capacity-fields-gate.sh`'s existing
Edit/MultiEdit `replace_all` handling (survey.md Finding 3) is
functionally superseded by `gate_reconstruct_write`, not independently
preserved — the swap removes a sixth hand-rolled copy of logic
`gate-lib.py` now owns canonically.

## Item 2 — semantic checks: section/adjacency, not whole-document substring

Closing survey.md Finding 4, generalizing the bounded-window technique
`headroom-gate.sh:85-96` already uses in this repo (precedent, not a new
invention) to the other three content-checking gates:

- **`capacity-fields-gate.sh`** (lines 88-97): after confirming the
  "Expansion trigger thresholds" heading exists, extract only the text
  from that heading to the next `^#+` heading (or end of document) via a
  small `awk`/Python slice, and run the `growth_rate`/`lead_time`/
  `safety_buffer`/percentile checks against that slice only — not
  `$content` in full. A `growth_rate` mention outside the threshold
  subsection no longer satisfies the check.
- **`threshold-gate.sh`** (lines 104-116): same heading-to-next-heading
  slice technique, scoped to whichever of "Expansion trigger thresholds"
  (record surface) or the nearest preceding `^##` heading containing
  "threshold"/"임계" (proposal surface, which has no fixed heading name
  today) the four-term and flat-percentage checks run against.
- **`citation-gate.sh`** (lines 83, 96-97): require `survey.md` /
  `scout-brief.md` to occur within a bounded adjacency window
  (`{0,200}` characters, matching the general shape of
  `headroom-gate.sh`'s `{0,120}` precedent, widened slightly since a
  citation line is typically a full sentence) of a `Basis:`/`Sources:`/
  `##.*Rationale`/`##.*Sources` anchor, not anywhere in the document —
  the current whole-document grep is satisfiable by an unrelated
  "we are NOT citing X" aside.
- **`forecast-method-gate.sh`** (lines 99-106): replace the document-length
  proxy ("Check 2") with an actual adjacency check — the recognized
  method keyword (or `대안:`/`alternative:` marker) and the data-shape
  term (`organic`/`inorganic`/`seasonal`/`campaign`/...) must both occur
  within a bounded window (`{0,300}` characters, generous enough for a
  full justification sentence) of each other, and that window's own
  non-whitespace length must be `>= 40` chars (the comment's original
  intent, now actually enforced structurally instead of via a
  whole-document `wc -c` proxy that a long unrelated document could
  satisfy without ever writing real justification prose).

## Item 3 — mandatory test cases, full green suite

Add to `tests/run-gate-tests.sh` (or a sibling file it sources) the six
case groups `docs/handbooks/gate-house-standard.md`'s "Standard test
harness" section makes mandatory, run against each of this repo's five
gates where the case is applicable to that gate's tool-matcher scope:

1. `Edit` with `replace_all: true` against a multiply-occurring
   `old_string` — assert the reconstructed content reflects every
   occurrence replaced, not just the first.
2. `MultiEdit` with a mix of `replace_all: true`/`false` edits in one
   call — assert per-edit `replace_all` is honored independently.
3. Malformed JSON payloads (truncated, non-object top level, empty
   string) piped to each gate — assert `exit 2` (deny), not `exit 0`.
4. Kill-switch environment variable set to an unrecognized value (e.g.
   `CAPACITY_THRESHOLD_GATE_OFF=banana`) — assert the gate stays
   **active** (still evaluates and can deny), per
   `gate_kill_switch_active`'s fixed convention.
5. An absolute `file_path` matching the same scope a relative-path
   fixture already matches, plus a `./`-prefixed variant of the same
   path — assert both are treated identically to the existing relative
   fixture.
6. A `Bash`-tool `tool_input.command` file write reaching the same target
   a `Write`-tool call to that path would hit (e.g. `cat > docs/issue-10/...`)
   — assert the gate's scope check fires on the Bash-tool call too, via
   `gate_bash_write_targets`.

`capacity-fields-gate.sh` additionally gets its first-ever case group
(survey.md Finding 5: zero coverage today) covering its existing
allow/deny behavior (missing heading, missing growth_rate/lead_time/
safety_buffer/percentile terms, non-terminal draft leniency) before the
six mandatory groups are layered on top. Phase 2's record documents the
full-suite green run verbatim, per the house standard's per-repo
migration checklist step 3-4 (re-run own tests + the six-case suite,
re-run `compliance-check.sh` clean).

## Item 4 — README realignment

Rewrite `README.md`'s Layout section (lines 22-28) to drop the three
ghost entries (`record-fields-gate.sh`, `trailer-gate.sh`,
`handbook-trigger-gate.sh` — deleted by issue-2, never restored) and
instead state plainly that trailer/record-fields/handbook-trigger
enforcement now comes from `core/hooks/hooks.json` firing globally keyed
off `CLAUDE_ROLE=capacity-planning`, matching what
`docs/issue-2/reports/implementation.md` already recorded as done. Add a
line for `capacity-planning/hooks/capacity-fields-gate.sh` (present today
but undocumented in Layout) and a "Gate-house standard" line pointing at
`docs/handbooks/gate-house-standard.md`, next to the existing
"Methodology plugin set (issue-7)" section, so a reader lands on the
canon reference instead of re-deriving it from the gate scripts alone.

## Compliance-detector evidence gate for phase 2

Per the house standard's per-repo migration checklist: phase 2 runs
`core/hooks/tests/compliance-check.sh` against this repo's `capacity-planning`,
`capacity-forecast-method`, `capacity-threshold-decomposition`,
`capacity-headroom-costnote`, `capacity-order-enforcement` hooks
directories both before (baseline violation list, expected non-clean
given survey.md's findings) and after item 1 lands (must be clean), and
records both outputs verbatim in `docs/issue-10/reports/capacity-planning.md`
as the evidence this A+ remediation actually closed the audit findings,
not just that new code was written.

## Not touched

- `capacity-planning/hooks/directive.sh`, `hooks.json` wiring shape, and
  every plugin's `.claude-plugin/plugin.json` — none vendor gate logic;
  nothing in items 1-4 changes their content.
- The domain semantics of what each gate checks for (growth_rate/
  lead_time/safety_buffer/percentile decomposition, headroom-as-band,
  citation chain, forecast-method selection) — issue-10 is a structural/
  mechanical remediation of *how* those checks are implemented and
  tested, not a re-litigation of *what* they require. `docs/issue-1`'s
  methodology norm stays the substantive source of truth.
