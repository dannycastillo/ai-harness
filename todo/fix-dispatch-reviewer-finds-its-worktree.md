# fix: dispatch reviewer finds its worktree

- **Priority:** high
- **Touches:** verbs/dispatch.sh, test/first-run.sh
- **Blocked by:** —

## Goal
`aih dispatch reviewer`, detached or not, starts the reviewer in the trunk
checkout again, and a test exercises a real dispatch so the path cannot
silently break.

## Why
d1b3053 (fix-a-stale-conf-lists-the-active-trunks) replaced the
reviewer branch's trunk check in `verbs/dispatch.sh` with
`ai_harness_require_trunk_checkout` and dropped the
`_wt=$(ai_harness_trunk_worktree)` assignment with it. The detach path
further down still does `cd "$_wt"`, so under `set -u` every
`dispatch reviewer` dies with `_wt: unbound variable`. `aih run` could
not start a single reviewer after that merge; the loop was stopped by
hand and the two waiting packets were judged by reviewers started by
hand. The review that passed d1b3053 checked the redirect from a claim
worktree and never a dispatch from the trunk, which is the gap the test
closes.

## Notes
- `verbs/dispatch.sh`, reviewer branch (line 62 on 2026-09-30): after
  `ai_harness_require_trunk_checkout "dispatch reviewer"`, set
  `_wt=$AI_HARNESS_REPO`. The helper has just proven the current
  directory is the trunk checkout, so that is the worktree. With `--print`
  the variable is unused; set it in both arms anyway so the later `cd`
  never depends on which arm ran.
- Do not restore the old inline check; the helper stays.
- `test/first-run.sh`: add a case that, in a throwaway repo with a trunk
  and a fake pending packet in `judge` phase, runs
  `aih dispatch reviewer --print` and then a real
  `aih dispatch reviewer` with `AI_HARNESS_AGENT_CMD` set to a stub such
  as `sh -c 'pwd >"$AI_HARNESS_STUB_OUT"'`, and asserts it exits 0 and the
  stub ran in the trunk path. The previous reviewer faked a packet the
  same way to reach the check; see the `fix-a-stale-conf` reviewer log
  under `.git/ai-harness/log/` for the shape it used.
- `set -u` is on in `bin/aih`; any variable a later block reads must be
  assigned on every path through the `case`. Worth one glance at the
  worker branch too: it sets `_wt` from `claim` on every path.

## Done when
- [ ] in the trunk checkout with a pending packet in `judge` phase, `aih dispatch reviewer --print` exits 0 and prints the boot prompt
- [ ] the same with `AI_HARNESS_AGENT_CMD` set to a stub exits 0 and runs the stub in the trunk checkout
- [ ] `sh test/first-run.sh` passes with the new case
- [ ] `aih gate` passes
