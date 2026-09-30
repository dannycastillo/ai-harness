# feat: init asks two questions and says three lines

- **Priority:** medium
- **Touches:** verbs/init.sh, templates/ai-harness.conf, test/first-run.sh, README.md, adapters/README.md
- **Blocked by:** —

## Goal
`aih init` run interactively asks where the trunk goes and whether to push
it, writes and commits the config, and ends with a short message; it never
prints the config it wrote.

## Why
Notes from a first run on 2026-09-30. The trunk name is long, the menu has
no way to name your own trunk, `Choice [1]:` is unexplained, and the
screen after the choice is a dump of the whole `.ai-harness.conf`. The
config's comments are dense and some predate the current verbs.

## Notes
Interactive flow (`aih init` with no `--yes`), in order:

1. Trunk menu. Three options; Enter picks 1, so no `[1]` after `Choice`:
   ```
   Trunk: where ai-harness merges finished work
     1) new branch and worktree aih-YYYYMMDD  (recommended)
     2) the branch checked out here (<branch>)
     3) a name you type
   Choice:
   ```
   - Default name is `aih-$(date -u +%Y%m%d)`; today the code and the
     `--yes` path build `ai-harness-$(date -u +%Y%m%d)` in two places in
     `verbs/init.sh`. Change both.
   - Option 3 prompts for a name and then behaves exactly like
     `--new-trunk <name>`: `git check-ref-format --branch`, refuse an
     existing branch, new worktree under the worktree root. Reuse the
     `_mode=new` / `_newname` path; don't add a fourth mode.
   - Option 2 stays as it is, hidden when HEAD is detached.
2. Push question, replacing the config printout and the `Write this
   config? [y/N]` confirmation:
   ```
   Push the trunk to its remote after each merge? [y/n]
   ```
   - Word it as "after each merge", not "after each commit": what
     `AI_HARNESS_PUSH_TRUNK=yes` does is push after a green `integrate`
     (adr-2026-09-27-push-the-trunk-only-when-the-conf-says-so).
   - The default answer is what init infers today: `y` when the trunk
     tracks an upstream, `n` otherwise. `--yes` keeps that inference and
     asks nothing, so the ADR's behavior is unchanged for scripts and
     `test/first-run.sh`.
   - Answering it is the confirmation; there is no third prompt.
3. Write the config, `todo/README.md`, `todo/new/.keep` and any adapters,
   commit on a new trunk as today, then end with three lines and a `cd`
   hint, nothing else:
   ```
   init: .ai-harness.conf written and committed on aih-20260930
   init: agents run as Claude's sonnet model by default
   init: change AI_HARNESS_AGENT_CMD in .ai-harness.conf to use another agent or model

     cd ../<project>-worktrees/aih-20260930
   ```
   - The `cd` line is the last thing printed, on its own indented line so
     it can be selected and pasted. A script cannot move the caller's
     shell, so this hint is the whole handoff; never try to `cd` for the
     user.
   - In `--trunk` mode nothing is committed and the user is already in
     the trunk; the first line says "written on <branch>; commit it"
     instead, and there is no `cd` line.
   - Drop the `--- .ai-harness.conf ---` block, the per-file `init: ...
     written` lines, and the `aih doctor` hint. Keep the push result
     lines (`pushed`, `not pushed — no remote`, the rejected-push
     warning): `test/first-run.sh` asserts on them.

For the "sonnet by default" line to be true, the template has to ship an
agent command. Today `templates/ai-harness.conf` leaves
`AI_HARNESS_AGENT_CMD` commented out, and `README.md` tells the user to
uncomment it. Decided for this todo: the template sets it, uncommented,
to the command this repo's own `.ai-harness.conf` uses:
```
AI_HARNESS_AGENT_CMD="claude --model sonnet --allowedTools Read,Edit,Write,Bash --permission-prompts none --max-budget-usd 10 -p"
```
`README.md` lines 36 to 38 and `adapters/README.md` line 44 describe the
unset path; reword them so unset is still supported (the print-the-command
path stays) but no longer the default `init` writes.

Config comment pass (`templates/ai-harness.conf`): one line per setting
saying what it controls, present tense, no argument for the design. Keep
only the header line naming ADR-09, the `@DETECTED@` warning shortened to
one line, and the no-stack comment `verbs/init.sh` appends. Check each
comment against the verb that reads the key: `lib/run.sh` for
`AGENT_TIMEOUT` and `RUN_POLL`, `lib/integrate.sh` for `PUSH_TRUNK`,
`lib/common.sh` for `WORKTREE_ROOT`. This can be its own `chore:` commit
on the same branch (AGENTS.md, one branch unless the split earns it).

Records that name the old format, and how to treat them:
- `adr-2026-09-29-init-opens-a-dated-trunk-worktree` writes
  `ai-harness-YYYYMMDD` in its Decision. The decision is that init opens
  a dated worktree; the prefix is a detail, so no superseding ADR. If the
  maintainer disagrees, write one and list the old ADR in Touches.
- `README.md` lines 25, 32, 72, 73 and `test/first-run.sh` line 15
  (`TRUNK=ai-harness-$DATE`) name it literally; change all five.
- The header comment of `verbs/init.sh` describes the printout and the
  `y` stop; rewrite it to the new flow. `aih init --help` reads that
  header.

`README.md` has an uncommitted edit on `main` at filing time; rebase onto
the trunk before touching it.

## Done when
- [ ] `aih init` in a terminal offers three trunk options, the prompt ends `Choice: `, and Enter picks the first
- [ ] option 1 and `aih init --yes` name the trunk `aih-YYYYMMDD` (UTC)
- [ ] option 3 accepts a typed name and refuses an invalid or existing one with the same messages `--new-trunk` gives
- [ ] the second and last prompt asks whether to push after each merge, defaulting to the upstream inference; `--yes` asks nothing
- [ ] no path through `aih init` prints the contents of `.ai-harness.conf`
- [ ] on a new trunk, init ends with the written-and-committed line, the sonnet default line, the `AI_HARNESS_AGENT_CMD` line, and a `cd <trunk path>` line, and nothing after them; in `--trunk` mode there is no `cd` line
- [ ] `templates/ai-harness.conf` sets `AI_HARNESS_AGENT_CMD` to the claude sonnet command, uncommented
- [ ] every comment in `templates/ai-harness.conf` is at most two lines and matches what the reading verb does
- [ ] `README.md`, `adapters/README.md`, `test/first-run.sh` and the `verbs/init.sh` header no longer mention `ai-harness-YYYYMMDD`, the config printout, or uncommenting the agent command
- [ ] `sh test/first-run.sh` passes
- [ ] `aih gate` passes
