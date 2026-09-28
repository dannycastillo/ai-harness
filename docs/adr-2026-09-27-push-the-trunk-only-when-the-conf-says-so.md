# ADR 2026-09-27: Push the trunk only when the conf says so

- **Status:** Accepted
- **Date:** 2026-09-27

## Context
- `integrate` reads the trunk's upstream before a merge and parks
  `trunk-diverged` when the trunk is behind it. It never pushes after a merge.
- On 2026-09-27 a run merged two todos onto the staging trunk. Nobody pushed
  it, and two PRs cut from it showed the run's own merges as their diff: a PR
  sees only origin, and the staging trunk exists to be promoted through one.
- Whether pushing is safe is the project's call, not the harness's to guess.
  A protected branch, or a trunk that is deliberately local-only, must not be
  pushed; a staging trunk meant to reach origin every merge should be.

## Decision
- `AI_HARNESS_PUSH_TRUNK`, `yes` or `no`. Unset means `no`, so a conf written
  before this key never starts pushing on upgrade.
- `aih init` writes `yes` when the trunk it detects already tracks a remote,
  `no` otherwise — it follows what the repo already does, once, at init time.
- On a green `integrate --continue`, after the merge commit lands: push the
  trunk to its upstream, fast-forward only, never `--force`. Skipped silently
  when the key isn't `yes` or the trunk has no upstream.
- A rejected push never undoes the merge. It writes a `@trunk - unpushed`
  event and prints one warning; the merge still exits as it would have. The
  next green merge tries the push again.
- `aih status` and `aih doctor` report an ahead trunk whenever it has an
  upstream, whatever the key says — worded differently only in whether
  `integrate` will clear it or a human must.

## Alternatives considered
- **Infer it from the upstream at run time** — a reader of the conf could no
  longer tell whether the harness pushes; the same reason gates and protected
  paths live in config (ADR-09, adr-2026-09-24-protected-paths-live-in-config).
- **Fail the merge on a rejected push** — the merge already passed the gate
  and is real work landed on trunk; undoing it over a push race would lose
  that for a problem the next merge fixes for free.
- **Push unconditionally whenever an upstream exists** — the failure this ADR
  fixes; a protected branch or a local-only trunk must opt in, not out.

## Consequences
- A conf upgraded from before this key keeps its old, silent behavior: no
  push, until a human sets the key.
- A rejected push is a warning a human can miss until the next `status` or
  `doctor`. That's the accepted cost of never blocking a landed merge on it.
- The two roles (worker, reviewer) still never push; this is `integrate`'s own
  post-merge step, run by the reviewer's verb, not by either role directly.
