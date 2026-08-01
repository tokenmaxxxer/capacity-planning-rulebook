# Proposal — issue-13: gate A+ final closeout (2026-08-01 re-audit, grade B)

Subject: issue-13. Phase 1 proposal only — no APPROVE requested here.

Basis: docs/issue-13/reports/capacity-planning/survey.md (current-state
findings) and docs/issue-13/reports/capacity-planning/scout-brief.md
(skip record — every fix below is reference-adoption of an already-landed
or already-in-repo pattern, not an open design choice).

## Scope

The 2026-08-01 re-audit (grade B) named six concrete residual defects
plus a README/manifest cleanliness requirement, on top of two already-
landed precondition fixes (core issue-75, on-the-record issue-182). This
proposal is the fix plan for phase 2; nothing here is applied yet.

## Fix plan, one item per confirmed defect (survey.md numbering)

1. **Source guard, all 5 gates + capacity-planning's own directive.sh.**
   Change every
   `. "${CLAUDE_PLUGIN_ROOT_CORE:-...}/hooks/lib/gate-lib.sh"` (and the
   one `role-directive.sh` source in `capacity-planning/hooks/directive.sh`)
   to append core-75's confirmed guard verbatim:
   `|| { echo "<gate-name>.sh: cannot source gate-lib.sh" >&2; exit 2; }`,
   substituting each script's own filename for `<gate-name>.sh` per the
   handbook's own per-gate-name convention. No other line changes.

2. **`= 2` rc mischeck -> `-ne 0`, 4 call sites.** In
   `capacity-fields-gate.sh` (both call sites),
   `forecast-method-gate.sh` (JSON-parse check), `citation-gate.sh`
   (JSON-parse check), and `headroom-gate.sh` (JSON-parse check), replace
   `[ "$rc" = 2 ]` / `[ $rc -eq 2 ]` with `[ "$rc" != 0 ]` /
   `[ $rc -ne 0 ]` — matching the form `threshold-gate.sh` and
   `headroom-gate.sh`'s own reconstruct-check already use correctly. Any
   nonzero exit from the embedded Python (not just the `deny()` helper's
   `sys.exit(2)`) now denies instead of silently falling through to an
   empty-scope allow.

3. **Symlink-safe root, all 5 gates.** Before calling
   `gate_lib.gate_normalize_path(root, fp)`, realpath the root exactly as
   `gate-lib.py`'s own docstring instructs: replace
   `root = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())` with
   `root = os.path.realpath(os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd()))`
   in each gate's Python payload (both the scope-check and, where
   present, any other call site). This does not change
   `gate_normalize_path` itself (core-owned, out of this rulebook's
   write scope) — only how this rulebook's own callers prepare its
   `root` argument, consistent with the function's documented contract.

4. **Percentile regex word boundary, `threshold-gate.sh`.** Change
   `grep -qE 'p[0-9]{1,3}(\.[0-9]+)?|percentile|백분위'` to require a
   non-alphanumeric (or start-of-string) boundary immediately before the
   `p`, e.g. `grep -qE '(^|[^[:alnum:]])p[0-9]{1,3}(\.[0-9]+)?|percentile|백분위'`,
   at both the percentile-presence check (line ~146) and the
   flat-percentage-prohibition check that shares the same pattern
   (line ~153), so `cap95`/`step2`/`http2`-style incidental substrings no
   longer satisfy a real percentile requirement.

5. **Headroom gate: scope to a slice, not the whole document.**
   Adopt `threshold-gate.sh`'s existing heading-slice pattern (lines
   109-138) in `headroom-gate.sh`: before the band-not-snapshot and
   cost-attribution checks, extract the slice from the record's
   "Expansion trigger thresholds" heading onward is not applicable here
   (headroom-costnote's own field is separate) — the equivalent fixed
   heading this plugin owns is the record's headroom/cost-note section;
   scope both checks (lines ~85-99) to that heading's slice (search for
   `^#+[^\n]*headroom[^\n]*\n(.*?)(?=\n#+\s|\Z)` case-insensitive, and
   equivalently for the cost note, falling back to whole-content only if
   no such heading exists — same fallback discipline
   `threshold-gate.sh` uses) instead of grepping the entire reconstructed
   `$content`.

6. **Add standalone `Edit`-tool test coverage.** Add at least one
   `"tool_name":"Edit"` case per gate (or a shared fixture reused across
   gates, matching the existing `MultiEdit` fixture's style) to
   `tests/run-gate-tests.sh`, asserting the same allow/deny behavior a
   parity `Write`/`MultiEdit` case gets for the same resulting content —
   closing the gap between the advertised `Write|Edit|MultiEdit` matcher
   and what the suite actually exercises.

7. **README ghost-path removal + verification pass.** Remove the
   `capacity-planning/agents/warrant-hunter.md` line from `README.md`'s
   "Layout" section (confirmed nonexistent). Phase 2 re-walks every
   relative path `README.md` and each plugin's `.claude-plugin/*.json`
   cite, link by link, to confirm the "0 ghost paths, 0 stale role
   names" requirement is actually met (survey.md's manual spot-check
   found the one path above and no stale role name, but was not
   exhaustive against every link).

## Precondition re-reference

Both preconditions are landed (survey.md's precondition-check section);
item 1 above applies core-75's confirmed guard string verbatim rather
than inventing a new one, and item 3 relies on on-the-record-182's
`CLAUDE_PLUGIN_ROOT_CORE` injection already reaching role sessions so the
non-fallback branch of the guard is the one that actually resolves in
production.

## Explicitly out of scope for this proposal

- Requirement 2 (matcher/code coverage parity) needs no source change —
  survey.md confirms the matcher's advertised `Write|Edit|MultiEdit`
  coverage is already reachable in each gate's Python payload via
  `gate_reconstruct_write`; item 6 above is the coverage gap's actual
  fix (a test gap, not a code gap).
- No change to `core/hooks/lib/gate-lib.py`'s `gate_normalize_path`
  itself — out of this rulebook's `write_scope: []` and out of scope for
  a role-report-only proposal; item 3's fix is caller-side only, per the
  function's own documented contract.
- No APPROVE requested in this PR. Phase 2 (applying items 1-7, running
  `compliance-check.sh` and the full `run-gate-lib-tests.sh`-equivalent
  suite including a missing-core case per requirement 3, and recording
  before/after evidence) opens only once a docs/specs/approvers.md
  account approves per contract v3 s19.
