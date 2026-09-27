# feat: integrate pushes the trunk when told

- **Priority:** high
- **Touches:** lib/integrate.sh, verbs/integrate.sh, lib/render.sh, verbs/doctor.sh, verbs/init.sh, templates/ai-harness.conf, README.md, NEW docs/adr-*.md
- **Blocked by:** —

## Goal
With `AI_HARNESS_PUSH_TRUNK="yes"` in `.ai-harness.conf`, a green merge ends
with the trunk pushed to its upstream, and whatever the setting, `status`
and `doctor` say when the trunk is ahead of it.

## Why
`integrate` reads the trunk's upstream before a merge and parks
`trunk-diverged` when the trunk is behind it, then merges and stops. The
merge commit stays local and nothing reports that the trunk is now ahead.
On 2026-09-27 a run merged two todos, the trunk was never pushed, and two
PRs cut from it showed the run's merges as their own diff. The staging
trunk exists to be promoted through a PR, and a PR sees only origin.
Whether to push is the project's call: a protected branch or a local-only
trunk must not be pushed, so it is a conf key, not a guess.

## Notes
- Conf: `AI_HARNESS_PUSH_TRUNK`, `yes` or `no`. Unset means `no`, so a
  conf written before this key never starts pushing on upgrade.
  `templates/ai-harness.conf` carries the key with a one-line comment;
  `verbs/init.sh` fills it with `yes` when the trunk tracks a remote at
  init time and `no` otherwise. Decided 2026-09-27 against inferring it
  from the upstream at run time: a reader of the conf must be able to say
  whether the harness pushes, the same reason gates and protected paths
  live there (ADR-09, adr-2026-09-24-protected-paths-live-in-config).
- Push: on the `pass` path of `integrate --continue`, after the merge is
  committed and the `merged` event written, `git push <upstream-remote>
  <trunk>`. Fast-forward only; never `--force`. Skipped silently when the
  key is not `yes` or the trunk has no upstream.
- A failed push never undoes the merge. Write a `@trunk - unpushed <why>`
  event, print one warning, exit as the merge would have. The next green
  merge tries again and clears it.
- Visibility, every setting: when the trunk has an upstream and is ahead,
  `ai_harness_render_status` prints `trunk    N ahead of <upstream>, aih
  integrate pushes it | push it by hand` after the loop line, and
  `verbs/doctor.sh`'s trunk row says the same. `git rev-list --count
  <upstream>..<trunk>` is the number. Behind is already integrate's park.
- `AGENTS.md` says never push without being asked. The sentence needs a
  clause that the conf is the asking; `AGENTS.md` is a protected path, so
  that edit is a human's after the merge, not this branch's.
- ADR on this branch as its own `doc:` commit: a conf key over inference,
  off by default, push failure is a warning. One screen.
- `test/render-fixture.sh` has no upstream, so its output must not change;
  add a case only if it can stay portable.

## Done when
- [ ] with `AI_HARNESS_PUSH_TRUNK="yes"` and a tracked trunk, a green `integrate --continue --verdict pass` leaves `<upstream>..<trunk>` empty
- [ ] with the key `no` or unset, or with an untracked trunk, `integrate` runs no `git push`
- [ ] a rejected push leaves the merge on the trunk, writes `@trunk - unpushed`, and exits as a green merge does
- [ ] `aih status` and `aih doctor` show the ahead count when the trunk is ahead of its upstream, and nothing when it is not
- [ ] `aih init` writes the key, `yes` when the trunk tracks a remote and `no` otherwise
- [ ] a new ADR in `docs/` records the key, its default, and the warning-not-failure rule
- [ ] `test/render-fixture.sh` output is unchanged
- [ ] `aih gate` passes
- [ ] human: `AGENTS.md`'s push sentence names the conf key as the exception
