# fix: a stale conf lists the active trunks

- **Priority:** high
- **Touches:** lib/common.sh, bin/aih, verbs/run.sh, verbs/integrate.sh, verbs/dispatch.sh, test/first-run.sh
- **Blocked by:** —

## Goal
Wherever a verb refuses to run because it is not in a trunk, `aih` says
which branch it is on, lists every active trunk on the machine with a
`cd` command that reruns the verb there, and says to run `aih init` when
there is none. That is the shared guard and the three trunk-only verbs
alike.

## Why
After every promotion `main`'s conf names the trunk that was just retired
(adr-2026-09-29-init-opens-a-dated-trunk-worktree, Consequences). `aih
status` on `main` then dies with `<retired trunk> is not checked out
anywhere; check it out, or start a new trunk with aih init`, which names
a branch that no longer exists and points away from the trunk that is
open. `ai_harness_sole_trunk_checkout` already finds that trunk from
`main`; the guard never asks it.

## Notes
- `lib/common.sh`: split `ai_harness_sole_trunk_checkout` (line 115).
  `ai_harness_trunk_checkouts` prints every `<branch><TAB><path>` whose
  conf names its own branch, one per line; `sole` keeps its name and
  contract as a filter on it for any caller that needs exactly one.
- `lib/common.sh`: `ai_harness_die_no_active_trunk` builds the message
  and dies `$EX_FAIL`. The branch is
  `git symbolic-ref --short -q HEAD || git rev-parse --short HEAD`. The
  verb to rerun is `$verb`, set in `bin/aih` before any guard runs.
  Shape, one trunk:

  ```
  aih: this branch (main) does not have an active aih trunk.
  Active aih trunk found at /path/to/worktrees/aih-20260929-x:
    cd /path/to/worktrees/aih-20260929-x && aih status
  ```

  Several: `Active aih trunks found:` then one `cd ... && aih <verb>` line
  per trunk, each prefixed by its branch name. None:
  `No active aih trunk on this machine; run aih init to create one.`
- Call it from the last `die` in `ai_harness_require_trunk_or_claim`
  (conf names a trunk checked out nowhere) and from the no-config branch
  in `bin/aih` (line 60), replacing both existing messages. The earlier
  `run this from the <trunk> checkout: cd <path>` die, for a trunk that
  is checked out elsewhere, is correct and stays.
- `run`, `integrate` and `dispatch reviewer` pass the shared guard from a
  claim worktree and then apply their own trunk-only check
  (`verbs/run.sh` line 37, `verbs/integrate.sh` line 41,
  `verbs/dispatch.sh` line 70), each dying with `<verb>: run it from the
  <trunk> checkout (none exists)` when no trunk is checked out. Replace
  the three copies with one `ai_harness_require_trunk_checkout <verb>` in
  `lib/common.sh`: in the trunk checkout it returns; trunk checked out
  elsewhere, it dies `run it from the <trunk> checkout: cd <path> && aih
  <verb>`; checked out nowhere, it calls `ai_harness_die_no_active_trunk`.
  Same words as the shared guard, so a user sees one message shape
  whichever verb refused.
- `test/first-run.sh` asserts the old strings at lines 56, 58, 76, 77,
  82, 83 and 100; update them to the new shape. Add cases: a stale conf
  on `main` naming a deleted branch with one open trunk; the same with
  two open trunks; the same with none.
- The ADR says the redirect is used when exactly one trunk checkout
  exists. Listing several instead of failing is the same decision applied
  more helpfully: nothing re-roots, the user still chooses. No new ADR
  unless the maintainer wants that line superseded; say so in the submit
  body either way.

## Done when
- [ ] from a checkout whose conf names a branch that exists nowhere, with one trunk checkout open, `aih status` exits 1 and prints the current branch, that trunk's path, and a `cd <path> && aih status` line
- [ ] with two trunk checkouts open, both are listed with their branch names
- [ ] with no trunk checkout open, the message says to run `aih init`
- [ ] from a checkout with no `.ai-harness.conf`, the message has the same shape
- [ ] a trunk that exists and is checked out elsewhere still gets `run this from the <trunk> checkout: cd <path>`
- [ ] `aih run`, `aih integrate --next` and `aih dispatch reviewer` from a claim worktree with no trunk checked out print the same active-trunks message, and from a claim worktree with the trunk open elsewhere print the `cd <path> && aih <verb>` redirect
- [ ] `sh test/first-run.sh` passes with the new cases
- [ ] `aih gate` passes
