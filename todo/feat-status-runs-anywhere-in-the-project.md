# feat: status runs from any checkout of the project

- **Priority:** medium
- **Touches:** bin/aih verbs/status.sh lib/common.sh test/first-run.sh
- **Blocked by:** fix-no-trunk-error-is-one-line.md

## Goal
`aih status` from any checkout of the project that is not a trunk or a
claim lists every active trunk and prints each one's status, exit 0.

## Why
Today it dies with a `cd` to type. Status is read-only and every trunk's
tree is known, so there is nothing to guess at. Several trunks per project
is coming, and this is the shape that already fits it.

## Notes
From a trunk checkout or a claim's worktree, nothing changes: the status
of that tree only. Elsewhere, exactly this on stdout:

```
aih: this branch (main) does not have an active aih trunk.

ACTIVE TRUNKS

1. /Users/Danny/personal/aih-test-2-worktrees/aih-test-20261001-testing
no run yet. aih run --all starts one; aih plan shows what it would do.
```

One numbered entry per trunk from `ai_harness_trunk_checkouts`
(`lib/common.sh`, every checkout whose conf names its own branch), each
followed by that trunk's full status, unindented, obtained by running
`"$AI_HARNESS_HOME/bin/aih" status` from inside that path. With no trunk
anywhere, `ai_harness_die_no_active_trunk` as today, which after the
blocking todo is the one-line error.

`bin/aih` (lines 66-83) dies before the verb loads when the tree has no
conf or is not a trunk or claim; `status` needs to get past both, the way
`gate` skips the guard, and decide for itself in `verbs/status.sh`. With
no conf sourced, nothing from it may be read on that path:
`ai_harness_trunk_checkouts` and `ai_harness_is_claim_worktree` read git
and the state dir, not the conf. A stale conf on `main` naming a retired
trunk (`stale_conf` in the test) takes this same path, so it lists the
trunks that are open.

The branch line is the one `ai_harness_die_no_active_trunk` prints; keep
one home for it (a small helper in `lib/common.sh` both call) rather than
a second copy in the verb.

Update the `Runs:` line in the header of `verbs/status.sh`.

The ADR adr-2026-09-29-init-opens-a-dated-trunk-worktree lists the verbs
that run anywhere and says the rest redirect rather than guess. `status`
joins the list without guessing, since it reads each trunk's own tree;
no new ADR, but say so in the commit message.

`test/first-run.sh` asserts the redirect for `status` at lines 70-74,
91-92, 114 and 119-128; those become success checks on the listing (the
branch line, `ACTIVE TRUNKS`, `1. $W`, and the trunk's own first line).
Lines 97-98 stay failures with the one-line error. `stale_conf` with two
trunks should show `1.` and `2.`. `sh test/first-run.sh` is the
`firstrun` gate; `aih gate --quick` does not run it, so run it yourself.

## Done when
- [ ] `aih status` from `main` with one trunk open prints the block above and exits 0
- [ ] with two trunks open it lists both, numbered, each followed by its status
- [ ] from the trunk checkout or a claim's worktree the output is unchanged
- [ ] with no trunk open it fails with the one-line error from the blocking todo
- [ ] `sh test/first-run.sh` passes with the updated assertions
- [ ] `aih gate` passes
