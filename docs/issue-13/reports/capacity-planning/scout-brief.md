# Scout brief — issue-13

Basis: survey.md (this directory) established the current-state findings
this brief steers against.

## Skip record

Scouting skipped. Reason: the spec leaves no design decision open — every
defect survey.md confirms has an authoritative, already-landed reference
fix inside this same ecosystem, not an open design choice needing external
exemplars:

- Source guard: core issue-75 (PR tokenmaxxxer/tokenmaxxxer-core#77,
  merged) fixed this exact defect across `core/hooks/*.sh` and specifies
  the guard string verbatim in `gate-lib.sh`'s usage comment and
  `docs/handbooks/gate-house-standard.md`'s transition note. Applying it
  here is direct reference-adoption, not a choice among alternatives.
- `= 2` rc mischeck: `threshold-gate.sh` in this same repo already uses
  the correct `[ $rc -ne 0 ]` form at both its call sites — the fix is
  matching this rulebook's own already-correct sibling gate, not sourcing
  an external pattern.
- Symlink bypass: `gate-lib.py`'s own docstring for `gate_normalize_path`
  states the caller-side fix directly ("callers needing symlink-safe
  resolution against a real project root should still realpath their own
  root before calling this").
- `p`+digit over-match: a word-boundary fix to an existing regex — no
  design space beyond "match what was intended."
- Headroom whole-document grep: `threshold-gate.sh`'s existing
  heading-slice pattern (lines 109-138) is the established in-repo
  precedent for exactly this defect class; headroom-gate.sh adopting it
  is parity, not a new design.
- Missing Edit-only test: mechanical test-coverage gap against an
  already-defined matcher surface (`Write|Edit|MultiEdit`).
- README ghost path: delete a reference to a nonexistent file.

None of these are product-shaped or methodology-shaped decisions with a
field of comparable systems to survey; they are conformance fixes to this
repo's own already-adopted core standard and this repo's own already-correct
sibling gate. No sweep, no scout-brief content beyond this skip record.
