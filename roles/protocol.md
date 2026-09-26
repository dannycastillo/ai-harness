# Protocol

The portable rules: how branches, commits and todos work under the harness,
same in every adopting repo. A project's own conventions — its ADRs, its
comment policy, its language — stay in that project's `AGENTS.md`.

## Git workflow

### Branch for everything

`main` is only ever written by a merge. Never commit to it directly, not even a
one-line fix or a typo. If you find yourself on `main` with uncommitted work,
create the branch first, then commit — the work moves with you.

### Four prefixes, nothing else

| Prefix  | Use for                                                  |
| ------- | -------------------------------------------------------- |
| `feat`  | new behavior someone using the tool can observe          |
| `fix`   | correcting behavior that was wrong                       |
| `doc`   | documentation only, including this file                  |
| `chore` | deps, build, tooling, restructuring — no behavior change |

`chore` covers moving code as well as maintaining it: an extraction that leaves
behavior identical is a chore however large its diff, because what a reader
needs to check is that nothing changed.

If a change doesn't fit one of these, it's doing two things — split it until
each piece fits.

### One branch unless the split earns it

A minor change in scope — a decision lands mid-branch, an answer widens the work
a little — stays on the branch you're on. Two branches cost two reviews and two
merges, and stacking one on the other pays that to preserve an intermediate
state nobody will check out.

Nothing is pushed until the merge, so the history isn't fixed yet:

```sh
git reset --soft main   # branch pointer back to main, every change still staged
```

Recommit from there in whatever shape reads best, and rename the branch when its
old name stops describing the work.

Split only when the halves could genuinely ship apart — when someone would want
to merge, revert, or bisect them separately.

### Naming

- **Branch:** `<prefix>/<short-kebab-description>` — `feat/pane-resize`
- **Commit subject:** `<prefix>: <imperative summary>` — `fix: stop the exit erase eating a line`

Imperative mood ("stop", "add", "align") because a commit describes what
applying it *does* to the tree, not what you did yesterday. The branch prefix
and its commits' prefixes normally match; when they don't, the branch takes the
prefix of its most significant change.

## Working in parallel

Several agents work this backlog at once, one todo each, in separate
worktrees, and trunk is written only by `aih integrate`. The mechanics and
the verbs are in `README.md`; each role's sequence is in `roles/`. `aih run`
works a set of todos unattended.

`Touches` in a todo is a reservation on paths, and it is the only thing that
decides what runs side by side.

## Todo

Work that needs doing lives in `todo/`, one file per item. `ls todo/` is the
backlog — if a file is there, the work is open.

### Filename is the branch name

`todo/<prefix>-<short-kebab>.md` → branch `<prefix>/<short-kebab>`.

```
todo/feat-pane-resize.md    →  git switch -c feat/pane-resize
todo/fix-empty-desc-line.md →  git switch -c fix/empty-desc-line
```

Same four prefixes as commits. No numbers: todos have no order, and two agents
filing at once would race for the same one.

### Shape

```markdown
# <prefix>: <short title>

- **Priority:** high | medium | low
- **Branch:** <prefix>/<short-kebab>
- **Touches:** paths or globs, or one of `ALL` / `NEW <glob>` / `UNKNOWN`
- **Blocked by:** other todo filenames, or `—`

## Goal
One sentence: what is true when this is done.

## Why
The reason it's worth doing. One or two lines.

## Notes
Constraints, file paths, function names, gotchas, ADRs that apply.
Everything needed to start without asking a question.

## Done when
- [ ] verifiable statement
- [ ] verifiable statement
- [ ] `aih gate` passes
```

### Priority

| Value    | Test                                                              |
| -------- | ----------------------------------------------------------------- |
| `high`   | the tool is wrong in a way a user hits, or this blocks other work  |
| `medium` | real work, no urgency                                              |
| `low`    | worth doing; fine if it never happens                              |

Priority is relative to what's in `todo/` right now, not absolute. If most of
the backlog is `high`, none of it is — re-rank rather than inflate.

```sh
grep '\*\*Priority:\*\*' todo/*.md
```

An agent filing a todo proposes a priority. The maintainer's edit is final, and priority
is the **only** field worth editing in place — unlike an ADR, a todo is a plan,
not a record. Rewrite it freely while it's still open.

Priority orders the queue; it does not override **Blocked by**. A blocked
`high` waits for the thing blocking it, whatever that thing's priority is.

### Touches, and why it's the precise one

`Touches` is what makes parallel work possible. It is a reservation on a set of
paths, and it is the only thing deciding what can run side by side.

Paths or globs, space- or comma-separated, repo-relative. No prose and no
backticks: a field a script cannot parse reserves nothing.

```
- **Touches:** lib/run.sh, verbs/run.sh
- **Touches:** lib/*
```

A `*` matches across `/`, so `lib/*` covers `lib/run.sh`.
That is the shell's `case` behaviour rather than a choice, and it errs the
useful way: too broad only costs serialization, too narrow puts two agents in
one file.

Three tokens stand in for a path list:

| Token         | Means                                                        |
| ------------- | ------------------------------------------------------------ |
| `ALL`         | the whole repo. Conflicts with everything, so it runs alone  |
| `NEW <glob>`  | creates files that don't exist yet, bounded by the glob      |
| `UNKNOWN`     | not scoped yet. Treated as `ALL` until someone scopes it     |

There is no `Excludes:`. An exclusion the scheduler has to reason about is a
collision it can get wrong; the nuance belongs in **Notes**, where a reader
acts on it instead.

Overlapping paths means run them one after the other, not side by side:

```sh
grep '\*\*Touches:\*\*' todo/*.md
```

If you discover mid-task that you must touch a file the todo didn't list,
**say so** — another agent may be in that file right now.

**Done when** is the contract. Finish all of it; don't do more than it asks. If
you spot adjacent work, file a todo for it rather than folding it in.

Every box must be checkable from the worker's own worktree. `run`, `integrate`,
and `dispatch reviewer` only run in the trunk checkout, so a box that depends
on one of them can't be verified where the worker sits; `gate`, `check`,
`plan`, and `status` run anywhere and are fair game. A box that can only be
checked in the trunk checkout is a human's, and should say so: prefix it
`human:`, or rewrite it as a static property of the diff that a worker can
check directly.

### Picking one up

1. `cd "$(aih claim <todo-stem>)"`. It cuts the branch and a worktree from
   trunk and reserves `Touches`. `aih dispatch worker` takes the top
   runnable one instead.
2. Read the todo file, and read in full any ADR it references.
3. Do the work. `aih gate --quick` before every commit, and
   `aih check` to see what `integrate` will say.
4. `git rm` the todo file as part of the final commit on the branch.
5. Rebase onto trunk if it moved, then `aih submit`.

Deleting the file on the branch means merging the work and clearing the backlog
are the same event — there's no second step to forget, and no status field that
two branches can conflict over. What got done is still recoverable:

```sh
git log --diff-filter=D --oneline -- todo/
```

If a todo's Notes contradict the code — it was written before the code moved —
say so before working around it. A stale todo is worth a sentence, not a silent
reinterpretation.

### Filing one

File a todo when you notice work that's real but out of scope for what you're
doing. Don't file what you're about to do anyway, and don't file a vague
"improve X" — if you can't write the **Done when**, you don't understand it
well enough to hand off.

Filing is not prioritizing. The maintainer decides what gets picked up.
