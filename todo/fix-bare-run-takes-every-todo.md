# fix: a bare aih run with nothing remembered takes every todo

- **Priority:** high
- **Touches:** verbs/run.sh, lib/run.sh, test/first-run.sh
- **Blocked by:** —

## Goal
`aih run` with no stems, no `--all`, and no set remembered on disk behaves
exactly as `aih run --all`: it records the set, works every todo, and
`aih status` afterwards shows that run.

## Why
Seen on 2026-10-01 in an onboarding sandbox. A newcomer ran bare `aih run`
four times. Each run worked the backlog and the last one merged, yet
`aih status` printed `no run yet` and nothing else, because no run was ever
recorded. The loop already treats a bare first run as every todo; only the
record is missing, so the report lies.

## Notes
- `verbs/run.sh` lines 41 to 51 write `run/set` and `run/all` only for
  `--all` or explicit stems. A bare run writes nothing.
  `ai_harness_run_set_names` (`lib/run.sh` line 21) then falls back to
  `every todo`, so the `started` event and the log line claim a set that
  was never stored.
- `ai_harness_render_status` (`lib/render.sh` line 273) keys on `run/set`
  existing. Without it, status takes the `no run yet` branch (line 288)
  for the rest of the repo's life, even after a merge `aih log` shows.
- Smallest fix: after the argument parse in `verbs/run.sh`, when `_all` is
  `no`, `_stems` is empty, and `run/set` does not exist, set `_all=yes`.
  The existing block then writes both files. A bare run with a set on disk
  still reuses it, unchanged.
- Update the header comment of `verbs/run.sh` so `aih run --help` says a
  bare run reuses the last set, or takes every todo when none is remembered
  (adr-2026-09-29-help-lives-in-the-verb: that block is the per-verb truth).
- `lib/run.sh` lines 15 to 16 and the `every todo` fallback at line 28 cover
  an older empty `run/set`. Leave the fallback; adjust the comment only if
  it reads wrong after the change.
- `test/first-run.sh` calls `run --all` at lines 82 and 99. Add a case that
  runs bare `aih run` in a fresh repo and asserts `aih status` afterwards
  prints a `run` line and not `no run yet`. `test/render-fixture.sh` shows
  how status output is asserted.
- `aih plan` with no stems already previews every todo, so no change there.

## Done when
- [ ] in a repo with no `run/set`, bare `aih run` writes `run/set` and `run/all` before its first tick, the same as `aih run --all`
- [ ] `aih status` after that run prints the run block with its rows, not `no run yet`
- [ ] bare `aih run` with a remembered set still reuses that set
- [ ] `aih run --help` states what a bare run does with and without a remembered set
- [ ] `test/first-run.sh` covers the bare run
- [ ] `aih gate` passes
