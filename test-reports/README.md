# Test evidence

Machine-readable test reports written by `scripts/run-integration-tests.sh` on
every fully passing run that covers a full suite (one file per run).

Releases are gated on them: `scripts/check-test-evidence.sh <mod>` — used by CI
in PRs and before creating release tags — requires a passing report whose
content fingerprint still matches the code being released. Version bumps and
changelog edits do not invalidate a report; any change to a mod's sources,
tests, or the test harness does.

Commit new reports together with the changes they cover. See
`scripts/lib/test-evidence.sh` for the fingerprint definition.
