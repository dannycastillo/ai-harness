# fix: a new trunk is pushed when the conf says so

- **Priority:** medium
- **Touches:** verbs/init.sh, lib/integrate.sh, lib/render.sh, verbs/doctor.sh, test/first-run.sh, README.md
- **Blocked by:** —

## Goal
With `AI_HARNESS_PUSH_TRUNK="yes"`, a trunk that `aih init --new-trunk`
opens tracks the remote from its first commit, and a trunk with no
upstream is reported rather than silently left local.

## Why
`ai_harness_ig_push` in `lib/integrate.sh` pushes only to the trunk's
configured upstream and returns 0 without a word when there is none. A
trunk `init` creates is a new local branch with no upstream, so on
2026-09-29 two trunks in a row ran every merge green and pushed nothing;
each was pushed by hand just before its promotion PR. `aih status` and
`aih doctor` could not show it either: the "ahead of origin" line also
keys off the upstream. A setting that says `yes` and does nothing, with
nothing printed, is the bug.

## Notes
- `verbs/init.sh`, after the commit (`_subject` block near the end): when
  the conf being written has `AI_HARNESS_PUSH_TRUNK="yes"` and the branch
  was created here (`_mode=new`), `git -C "$_dest" push -u <remote>
  "$_trunk"`. The remote is the one `main`'s or the current branch's
  upstream uses, else `origin` if it exists; with no remote at all, skip
  and print why. Print the push as an `init:` line like the others. A
  rejected push warns and leaves the trunk local, like `integrate` does.
  Read the value from the conf just written, not the environment: in the
  copy case the file keeps the source conf's value, in the fresh case
  `init` computed `_push_trunk` from whether the trunk tracks a remote,
  which for a new branch is always `no`; that computation stays.
- `lib/integrate.sh`, `ai_harness_ig_push`: when the setting is `yes` and
  there is no upstream, `warn` once per merge: `integrate: <trunk> has no
  upstream; push it once with -u and later merges follow`, and record an
  `@trunk - unpushed` event like the rejected-push branch does. Still
  return 0: the merge stands (adr-2026-09-27-push-the-trunk-only-when-the-
  conf-says-so).
- `verbs/doctor.sh`, the `trunk` row: with the setting `yes` and no
  upstream, append `no upstream — integrate cannot push`. `lib/render.sh`'s
  `ai_harness_render_trunk_ahead` returns early on no upstream; add the
  case there so `status` says it too, or in doctor alone if render is the
  wrong altitude — say which in the commit.
- `test/first-run.sh`: the `dated_trunk` case runs against a throwaway
  repo with no remote; add a case with a bare remote and the setting
  `yes`, and assert the new trunk has an upstream after init. Keep the
  no-remote case asserting init still succeeds and says why it did not push.
- README.md, Configuration, the `AI_HARNESS_PUSH_TRUNK` bullet: say init
  pushes a new trunk with `-u` under `yes`, and that a trunk with no
  upstream is reported by `doctor` and `status`.
- The push is the one outward action in `init`; the conf is the asking, the
  same reasoning the ADR gives for the merge-time push. No new ADR.

## Done when
- [ ] in a repo with a remote and `AI_HARNESS_PUSH_TRUNK="yes"`, `aih init --new-trunk t --yes` leaves `t` tracking `<remote>/t` and prints that it pushed
- [ ] in a repo with no remote, the same command succeeds, commits, and prints why it did not push
- [ ] with the setting `yes` and a trunk with no upstream, `aih integrate` warns and records an `unpushed` event, and the merge still lands
- [ ] `aih doctor` on such a trunk says it has no upstream
- [ ] `sh test/first-run.sh` passes with the new case
- [ ] `aih gate` passes
