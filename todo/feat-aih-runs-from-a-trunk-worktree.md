# feat: aih runs from a trunk worktree

- **Priority:** high
- **Touches:** lib/state.sh, lib/selftest.sh, verbs/doctor.sh, templates/ai-harness.conf, README.md
- **Blocked by:** —

## Goal
A developer whose trunk is a linked worktree, of a normal clone or of a bare
repository, runs every verb from it with no layout that turns trunk into a
claim, and the README says which layouts are supported and where the
worktree root lands in each.

## Why
Developers adopting the harness are likely to already use worktrees, and the
common `.bare` layout keeps every checkout, trunk included, under one folder.
Tried on 2026-09-27 from a trunk worktree, running claim, submit and
integrate through to the merge:

- normal clone, main checkout on another branch, trunk in a linked worktree: works
- bare repository at `project/.bare`, trunk at `project/trunk`: works
- bare repository, trunk at `project/worktrees/trunk` with
  `AI_HARNESS_WORKTREE_ROOT="worktrees"`: `doctor --repair` rebuilds
  `claims/trunk` with empty Touches, and from then on every `aih claim` dies
  with `Touches meet active claim trunk on ALL`, `aih plan` exits 1 with no
  output, and `aih status` prints an empty table

Nothing recovers the third case but deleting the claim file by hand. The
design already carries the rest: state is under `--git-common-dir`, trunk is
discovered from `git worktree list`, and `run`, `integrate` and `dispatch`
compare the current toplevel to that. This todo closes the one gap and writes
down what is supported.

## Notes
- `ai_harness_state_repair` in `lib/state.sh` skips only the main worktree
  (`[ "$_p" = "$_main" ] && continue`) and rebuilds a claim for every other
  worktree under the root. Skip the worktree whose branch is
  `$AI_HARNESS_TRUNK`, and skip any worktree whose branch maps to no
  `todo/<stem>.md` on trunk, logging it once as
  `  ~ <dir>  not a claim: no todo on <trunk>`. A real claim always has its
  todo on trunk until the merge, so the second rule covers a user's own
  scratch worktrees under the root too. Repair must never write a claim with
  empty `touches=`, because empty means `ALL`.
- `lib/selftest.sh` already cuts a throwaway linked worktree to compare state
  dirs. Extend it: cut the throwaway under the worktree root on a branch
  that is not a todo, run repair, and assert no claim was rebuilt for it.
  It runs under `doctor --selftest`, so the assertion ships with the tree.
- `ai_harness_main_worktree` in `lib/common.sh` is the parent of the common
  dir. In a bare layout that is the folder holding `.bare`, so a relative
  `AI_HARNESS_WORKTREE_ROOT` resolves against `project/`, and the default
  `../<project>-worktrees` lands beside `project/`. Keep that; do not change
  `lib/common.sh`. Say it in `templates/ai-harness.conf` next to the key
  and in the README's Setup section, where "relative to the main worktree"
  is wrong for a bare repository, which has none. Name the three layouts
  above as supported, and say that `.bare` users who want the root inside
  `project/` set the key to a bare name such as `worktrees`.
- `verbs/doctor.sh` prints `worktrees N (including the main one)` when the
  first entry of `git worktree list` is a bare repository. Count only
  checkouts, and never call a bare repository the main worktree.
- `verbs/init.sh` is not in Touches: it derives trunk from the current
  checkout's HEAD, which is right from a trunk worktree, and its default
  root stays. If the work needs it, say so.
- `lib/render.sh`'s `ai_harness_render_path` strips the main-worktree
  prefix; in a bare layout that prefix is `project/`, which reads fine.
  Not in Touches.

## Done when
- [ ] with trunk checked out under the worktree root, `aih doctor --repair` rebuilds no claim for it, and `aih claim`, `aih plan` and `aih status` behave as they do from a plain checkout
- [ ] a worktree under the root on a branch with no todo on trunk is reported by repair and produces no claim
- [ ] `aih doctor --selftest` covers the point above and fails when the skip is removed
- [ ] `aih doctor` from a bare-repository trunk worktree never says "including the main one"
- [ ] README's Setup section names the three supported layouts and where a relative `AI_HARNESS_WORKTREE_ROOT` lands in a bare repository, and `templates/ai-harness.conf` says the same beside the key
- [ ] claim, submit and `integrate --continue --verdict pass` complete from a trunk worktree in each of the three layouts
- [ ] `test/render-fixture.sh` output is unchanged
- [ ] `aih gate` passes
