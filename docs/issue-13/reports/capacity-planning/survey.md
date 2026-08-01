# Survey — issue-13 (gate A+ final closeout: residual re-audit defects)

Subject: issue-13. Current-state survey preceding scout-brief.md and the
proposal, per contract v3 s19 / capacity-order-enforcement's
survey -> scout-brief -> proposal sequencing.

## Precondition check (both landed)

- core issue-75 (PR tokenmaxxxer/tokenmaxxxer-core#77, merged
  2026-08-01T09:02:47Z): confirmed the guarded-source form is
  `. "$path" || { echo "<gate-name>.sh: cannot source gate-lib.sh" >&2; exit 2; }`,
  added `gate_bash_write_targets` to `gate-lib.py` (sh/py parity), added
  `compliance-check.sh`'s unguarded-source check, and made the
  missing-core deny case (group 7) mandatory in
  `run-gate-lib-tests.sh`. `docs/handbooks/gate-house-standard.md`'s
  "Transition note (issue-75, ...)" section is the authoritative
  reference for the exact guard string this rulebook must adopt.
- on-the-record issue-182 (closed): spawn.py now injects
  `CLAUDE_PLUGIN_ROOT_CORE` at role-session spawn, closing the
  unreachable-core deployment gap the source guard defends against.

Both are landed on their respective `main` branches; this proposal
reference-applies core-75's confirmed guard string rather than
re-deriving one.

## This rulebook's current gate inventory

Five gates, all sourcing `core/hooks/lib/gate-lib.sh` via
`CLAUDE_PLUGIN_ROOT_CORE` fallback to `../../core`:

- `capacity-planning/hooks/capacity-fields-gate.sh`
- `capacity-order-enforcement/hooks/citation-gate.sh`
- `capacity-threshold-decomposition/hooks/threshold-gate.sh`
- `capacity-forecast-method/hooks/forecast-method-gate.sh`
- `capacity-headroom-costnote/hooks/headroom-gate.sh`

Plus five `directive.sh` SessionStart hooks (one per plugin); the four
plugin-level ones already carry a `__fc` fail-closed trap wrapper,
`capacity-planning/hooks/directive.sh` does not and sources
`role-directive.sh` (not `gate-lib.sh`) with no `||` guard either.

## Re-audit findings, verified against current source (2026-08-01)

1. **Source guard missing (all 5 gates).** `grep -rn 'gate-lib.sh'
   --include=*.sh .` shows none of the five gate scripts carry the `||`
   guard core-75 made mandatory — every one is a bare
   `. "${CLAUDE_PLUGIN_ROOT_CORE:-...}/hooks/lib/gate-lib.sh"` with no
   fallback. Under an unreachable-core topology this is the exact
   fail-open core-75 documented: the source produces no `gate_*`
   functions, `gate_kill_switch_active` returns 127, and
   `gate_kill_switch_active ... || { exit 0; }` reads that as the kill
   switch being off. `capacity-planning/hooks/directive.sh`'s
   `role-directive.sh` source has the same gap.

2. **Subshell rc mischeck (`= 2` comparison), fail-open on other
   nonzero.** The JSON-parse-stage rc check uses `[ "$rc" = 2 ]` /
   `[ $rc -eq 2 ]` in four of the five gates —
   `capacity-fields-gate.sh` (two call sites, lines ~34 and ~71),
   `forecast-method-gate.sh` (line ~34), `citation-gate.sh` (line ~43),
   `headroom-gate.sh` (line ~36, first check only — its reconstruct
   check at line ~71 already correctly uses `-ne 0`). Each gate's
   embedded Python only calls `sys.exit(2)` through its own `deny()`
   helper; any *other* nonzero exit (an uncaught exception, e.g. a
   `KeyError`/`TypeError` on unexpected payload shape, which Python
   exits with code 1) is not `= 2`, so the check silently falls through,
   `$kind`/`$file_path` ends up empty or truncated, and every gate's own
   "empty scope -> gate_allow" branch admits the write. Contrast with
   `threshold-gate.sh`, which already uses `[ $rc -ne 0 ]` at both call
   sites (lines 44, 85) — the correct, already-present form in this same
   rulebook.

3. **Symlink bypass.** `gate_lib.gate_normalize_path(root, path)`
   (`core/hooks/lib/gate-lib.py`) is documented as pure string/path
   algebra with **no** filesystem touch: "This does NOT touch the real
   filesystem (no os.path.realpath / symlink resolution) — callers
   needing symlink-safe resolution against a real project root should
   still realpath their own `root` before calling this." All five gates
   call it as `gate_lib.gate_normalize_path(root, fp)` with
   `root = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())` —
   un-realpath'd. A symlink placed inside the project tree (e.g. a
   `docs/issue-N` entry symlinked to a path outside the intended scope,
   or `CLAUDE_PROJECT_DIR` itself resolving through a symlinked
   checkout) lets the string-level scope check pass while the actual
   write lands somewhere the check never inspected.

4. **`p`+digit over-match on percentile check.**
   `threshold-gate.sh` line 146/152-153:
   `grep -qE 'p[0-9]{1,3}(\.[0-9]+)?|percentile|백분위'` has no word
   boundary before `p`. Any token merely containing `p` immediately
   followed by 1-3 digits satisfies the percentile requirement even
   with no percentile intent — e.g. `step2`, `cap95`, `group50`,
   `http2` all contain a `pNN` substring. A proposal/record can pass the
   percentile-stated requirement (and the flat-percentage-prohibition
   check that also keys off the same pattern) without ever stating a
   real percentile.

5. **Headroom gate greps the whole reconstructed document, not a
   scoped slice.** `headroom-gate.sh` lines 85-99 run
   `printf '%s' "$lc" | grep -qE ...` directly against the entire
   lower-cased `$content` for both the band-not-snapshot and the
   cost-attribution checks. `threshold-gate.sh` (lines 109-138) already
   established the scoped-slice pattern for this exact class of check —
   isolate the relevant heading's slice (record: fixed "Expansion
   trigger thresholds" heading; proposal surface n/a here since this
   plugin is phase-2-record-only) before grepping — specifically to
   avoid a stray "headroom"/"cost" mention elsewhere in a long record
   satisfying the check via unrelated document content. `headroom-gate.sh`
   never adopted that pattern; it is the "문서 전역 grep 잔존" (whole-document
   grep leftover) the issue names.

6. **Zero standalone `Edit`-tool test coverage.** `tests/run-gate-tests.sh`
   (225 lines) constructs payloads with `"tool_name":"Write"` (multiple
   sites) and one `"tool_name":"MultiEdit"` case (line 137); `grep -c
   '"Edit"' tests/run-gate-tests.sh` returns `0`. Every plugin's
   `hooks.json` matcher advertises `"Write|Edit|MultiEdit"` — the `Edit`
   branch through `gate_reconstruct_write` is live in production but has
   no test asserting it behaves like the `Write`/`MultiEdit` cases
   (single-edit `Edit` exercises different code inside
   `gate_reconstruct_write` than `MultiEdit`'s edits-array path).

7. **README ghost path.** `README.md` line 27 lists
   `capacity-planning/agents/warrant-hunter.md` under "Layout"; the
   `capacity-planning/agents/` directory does not exist in this repo.
   All other `README.md`-referenced paths checked this survey
   (`docs/issue-2/reports/implementation.md`,
   `docs/issue-7/proposals/enforcement-machinery-deepening.md`,
   `docs/handbooks/capacity-planning/forecast-checklist.md`,
   `docs/issue-10/reports/capacity-planning.md`,
   `docs/handbooks/gate-house-standard.md`, `docs/specs/approvers.md`,
   `.claude-plugin/marketplace.json`'s five plugin entries) resolve.
   The issue's "README·manifest 옛 역할명·유령 파일 잔재 0" requirement names
   two ghost-path instances and a stale-role-name check; this role's
   canonical name (`capacity-planning`) and its hand-off target
   (`performance-engineering`) both match on-the-record's current
   `roles/` registry (`capacity-planning.json`,
   `performance-engineering.json` present, no rename found), so no
   stale-role-name instance was found in this repo's README/manifest —
   the scout-brief and proposal record this as a checked-clean item, and
   the `warrant-hunter.md` reference is the one concrete ghost path this
   survey confirms; the proposal's remediation step re-derives whether a
   second ghost reference exists once the fix pass actually walks every
   README-cited path link-by-link (phase 2), since a survey-time manual
   check is not exhaustive against every relative link in the document.

## Gap against issue's requirement list

- Req 1 (fix all defects above): none of the 7 fixed yet — this is
  phase-1 (proposal only); phase 2 does the fix once approved.
- Req 2 (hooks.json matcher vs. code coverage parity): matcher already
  advertises `Write|Edit|MultiEdit` on all five gates and all five gates'
  Python payload calls `gate_reconstruct_write` which handles all three
  tool shapes — the *advertised* coverage is real in code; finding 6
  above is that the coverage is untested for `Edit`, not that it is
  unreachable.
- Req 3 (missing-core case + compliance-check green): not yet run
  against this rulebook — phase 2 work, blocked on the proposal's fix
  plan being approved.
- Req 4 (README/manifest ghost/stale-name = 0): one confirmed ghost path
  (`warrant-hunter.md`); no confirmed stale role name.
