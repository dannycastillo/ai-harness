# feat: aih runs from a trunk worktree

- **Priority:** high
- **Touches:** lib/state.sh, lib/selftest.sh, verbs/doctor.sh, templates/ai-harness.conf, README.md, NEW test/worktree-layouts.sh
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
down what is supported. Decided 2026-09-27: the plain clone is the case that
must not move; bare support is worth having only while it costs nothing
there.

## Notes
- `ai_harness_state_repair` in `lib/state.sh` skips only the main worktree
  (`[ "$_p" = "$_main" ] && continue`) and rebuilds a claim for every other
  worktree under the root. One rule replaces that: a worktree is a claim only
  when its branch maps to a stem whose `todo/<stem>.md` exists on
  `$AI_HARNESS_TRUNK`. A real claim always has its todo on trunk until the
  merge, so the rule keeps every claim repair rebuilds today, and it excludes
  the trunk worktree and a user's scratch worktrees without naming either.
  Log each skip once as `  ~ <dir>  not a claim: no todo on <trunk>`. Repair
  must never write a claim with empty `touches=`, because empty means `ALL`.
- Put the rule in a helper, `ai_harness_state_worktree_claim <path>
  <branch>` or similar, that prints the stem or fails. Repair calls it; so
  does the self-test.
- `lib/selftest.sh` already cuts a throwaway linked worktree under `mktemp`
  to compare state dirs. Add a second check there: the throwaway is on a
  branch that maps to no todo, so the helper must reject it. Do not run
  repair from the self-test: it rewrites the live claims directory, and
  `doctor --selftest` may run while a loop is up.
- `test/worktree-layouts.sh`, new, alongside `test/render-fixture.sh`: for
  each of the three layouts above, clone this checkout into a temp
  directory, cut trunk as a worktree, write a one-line todo of its own into
  the scratch clone and commit it to trunk there, then run `claim`, a
  commit, `submit`, `integrate --next` and `integrate --continue --verdict
  pass` from the trunk worktree, and in the third layout `doctor --repair`
  first. It runs `$AI_HARNESS_HOME/bin/aih`, needs the gates the conf names
  to be runnable, and prints one line per layout. It is a test, not a gate.
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
- [ ] `aih doctor --selftest` rejects a throwaway worktree through the helper, without running repair, and fails when the rule is removed
- [ ] `aih doctor` from a bare-repository trunk worktree never says "including the main one"
- [ ] README's Setup section names the three supported layouts and where a relative `AI_HARNESS_WORKTREE_ROOT` lands in a bare repository, and `templates/ai-harness.conf` says the same beside the key
- [ ] `test/worktree-layouts.sh` passes, running claim, submit and a green merge from a trunk worktree in each of the three layouts
- [ ] `test/render-fixture.sh` output is unchanged
- [ ] `aih gate` passes
