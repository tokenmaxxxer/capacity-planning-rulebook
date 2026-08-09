
## after-proposal — stance 2: make the guard go silent on malformed input

Verdict: NO FINDING
Seed: docs/issue-19/proposals/adopt-test-env-resolution.md (diff HEAD~1..HEAD, docs-only, no code yet)
cap_seconds: 60
tier: default
diff_stat_lines: docs-only proposal, no run-gate-tests.sh changes landed
started_at: 2026-08-09T00:00:00Z
ended_at: 2026-08-09T00:01:00Z

resolve_core() is not implemented — only the proposal doc exists (tests/run-gate-tests.sh
has no such function; git log/diff confirm no code change yet). Nothing to run that could
go silent. As a proxy, tested the existing gate hooks' own
`${CLAUDE_PLUGIN_ROOT_CORE:-...}` fallback (which the proposal explicitly leaves
unchanged) against malformed input — empty-string vs unset:

```
export CLAUDE_PLUGIN_ROOT_CORE=""
export CLAUDE_PROJECT_DIR="$(mktemp -d)"
printf '{}' | bash capacity-planning/hooks/capacity-fields-gate.sh
```
Observed: bash `:-` parameter expansion treats empty string same as unset, so it falls
through to the sibling `../../core` computation, that path doesn't exist, and the hook
fails loudly and correctly: `cd: .../../../core: No such file or directory`,
`.../hooks/lib/gate-lib.sh: No such file or directory`, `capacity-fields-gate.sh: cannot
source gate-lib.sh`, `rc=2`. This is fail-closed and non-silent, not a defect.

No reproducible silent-failure exists yet because there is no code to run. Revisit this
stance once resolve_core() actually lands.
