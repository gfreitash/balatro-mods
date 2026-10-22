# Test evidence

One machine-readable report per mod: `<mod>.json`. Each run mode (`main`, `pb`)
is a block under `runs`, written by `scripts/run-integration-tests.sh` on a
fully passing run that covers that mode's required suite(s). A verified run
replaces only the mode it covers, so the file always describes the latest state
verified for that mod.

Releases are gated on them: `scripts/check-test-evidence.sh <mod>` — used by CI
in PRs and before creating release tags — requires every required mode to have
a passing block whose content fingerprint still matches the code being
released. Version bumps and changelog edits do not invalidate a report; any
change to a mod's sources, tests, or the test harness does.

Commit the updated report together with the changes it covers. Older reports
remain in git history. See `scripts/lib/test-evidence.sh` for the fingerprint
definition and the report schema.
