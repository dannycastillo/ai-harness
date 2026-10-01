# Protocol

The portable rules: how branches, commits and todos work under the harness,
same in every adopting repo. A project's own conventions — its ADRs, its
comment policy, its language — stay in that project's `AGENTS.md`.

## Git workflow

The project declares its prefixes in `AI_HARNESS_PREFIXES`; what each one
means is that project's `AGENTS.md`. A prefix names both the todo file and the
commit subject — `<prefix>: <imperative summary>` — and the branch is
`<prefix>/<rest>` of the todo's filename, `<rest>` being everything after the
prefix and its hyphen.

## Working in parallel

Several agents work this backlog at once, one todo each, in separate
worktrees, and trunk is written only by `aih integrate`. `aih help` lists the
verbs and `aih <verb> --help` documents each; each role's sequence is in
`roles/`. `aih run` works a fixed set of todos unattended.

A verb runs in one of three places: anywhere, the trunk checkout, or a claim's
worktree. A worker's verbs run from its own worktree; the trunk checkout is
the reviewer's and the loop's. `aih <verb> --help` says which, and is the
per-verb truth.

`Touches` in a todo is a reservation on paths, and it is the only thing that
decides what runs side by side.


## Worktree layouts

Trunk may be checked out anywhere; every verb runs from it. Supported:

- a normal clone, its main checkout on any branch, trunk in a linked worktree
- a bare repository at `project/.bare`, trunk at `project/trunk`
- the same bare repository with trunk at `project/worktrees/trunk` and
  `AI_HARNESS_WORKTREE_ROOT="worktrees"`

A relative `AI_HARNESS_WORKTREE_ROOT` resolves against the main worktree. A
bare repository has none, so it resolves against the folder holding `.bare`:
the default `../<project>-worktrees` lands beside `project/`, and a bare name
such as `worktrees` lands inside it. `doctor --repair` rebuilds a claim only
for a worktree under the root whose branch has a todo on trunk, so trunk and
scratch worktrees there are reported and left alone.

- A gate is a function named `ai_harness_gate_<name>` plus a
  `AI_HARNESS_GATE_TOOLS_<name>` list of what it needs on `PATH`.
- A declared gate whose tool is missing stops the run with exit `4`. It is
  never skipped. A project without a tool declares fewer gates.
- An empty gate list warns and passes with exit `0`. Nothing was declared,
  so nothing is skipped; exit `4` is only for a gate that is declared and
  cannot run.
- `.ai-harness.conf` is always a hard stop in `check`, so an agent cannot
  loosen the gate and merge the change. The config cannot unprotect itself.
- `AI_HARNESS_PROTECTED` lists globs that park for a human even when a todo
  declares them. Unset, it is `AGENTS.md`; set it to add to that or to free
  a path.
- `AI_HARNESS_PUSH_TRUNK="yes"` pushes the trunk to its upstream, fast-forward
  only, after every green merge. Unset or `no`: the merge stays local and a
  human pushes it. `aih init` sets it from whether the trunk already tracks a
  remote. Under `yes`, `aih init` pushes a new trunk with `-u` so it tracks
  the remote from its first commit. A rejected push warns and leaves the merge
  on trunk; `aih status` and `aih doctor` show an ahead trunk either way, and
  a trunk with no upstream under `yes`.

## State

Coordination state lives in `$(git rev-parse --git-common-dir)/ai-harness/`:
`claims/`, `lock/`, `tmp/`, `submitted/`, `parked/`, `integrate/`, `agents/`,
`log/` and `events`.

- `agents/<todo>.<role>` records a detached agent: pid, command, start, log,
  and once it ends, its exit code. While the record exists nothing dispatches
  that todo again. It goes when the claim goes: a merge, or `abandon`.
- `log/` holds each agent's output and is never cleaned by the harness.
- `events` is one line per thing that happened. `aih log` joins it with
  the merge trailers, which are the durable record.

- One copy, shared by every worktree. Git never tracks it.
- Git is the authority; the files annotate it.
  `rm -rf .git/ai-harness && aih doctor --repair` is safe.
- A stale lock is reported, never stolen. `aih unlock` is manual on purpose.
- The durable record will be the merge commits' `AI-Harness-*` trailers.




## The two roles

A different session plays each role. The session that writes a diff never
reviews it. Each role ends its work by running one verb, and the verb does
every write to shared state: no agent runs `git merge`.

| Role     | Does                                                                  | Never                                          |
| -------- | --------------------------------------------------------------------- | ---------------------------------------------- |
| worker   | claims one todo, works it in its own worktree, rebases, `submit`s     | merges, or edits outside its `Touches`         |
| reviewer | verifies a packet's **Done when**, then `integrate --continue`s       | rebases a branch, resolves a conflict, or cleans trunk |

A human or interactive agent session owns everything the two roles stop on: parks, stale locks, pauses.

## Where the verbs are documented

The tool documents itself, so the copy you have is the copy you read:

- `aih help` lists the verbs of the installed copy.
- `aih <verb> --help` says what one verb reads, writes and refuses, and where
  it runs.
- `aih protocol` prints the shared rules for branches, commits and todos.


## Running N workers

`run` is a shell loop, not an agent (ADR-10). It holds no state: every tick it
reaps exited agents, kills any past `AI_HARNESS_AGENT_TIMEOUT`, dispatches
workers up to `AI_HARNESS_MAX_WORKERS` from `plan`, and moves the queue one step:
`integrate --next`, then a detached reviewer for the packet. It exits when
nothing is runnable and nothing is in flight, or on a stop a human owns.

```sh
aih run fix-a fix-b --detach           # remembers the set; a bare run reuses it
aih run --all --detach                 # the todos in todo/ now; later ones wait for the next run
aih status                             # the run: loop, then a row per todo and why
aih log                                # what happened
aih pause "trunk needs a look"         # no new claims; queued work still merges
aih stop                               # kill the loop and every agent
```

- Killing the loop kills nothing else. Agents finish and submit; a restarted
  loop finds their submissions and carries on.
- Dispatch is at most once. A worker that exits without submitting, a park and
  a reject are terminal until a human acts: `abandon` to run it again, or
  resubmit from its worktree.
- A reviewer that exits with the judgment pending is reported `lost` and never
  respawned. `aih dispatch reviewer --detach` starts another by hand.
- A park on `@trunk` stops the loop. Trunk is a human's to fix.

By hand, one worker at a time:

```sh
aih plan                               # what can run now, and why the rest cannot
eval "$(aih dispatch worker)"          # claims the top runnable todo, starts the agent
aih status                             # every todo's row: runnable, held, claimed, parked, merged
```

`dispatch` starts `$AI_HARNESS_AGENT_CMD` with a one-line boot prompt that ends
with `aih submit`. With the command unset, it prints the `cd` and the
prompt for you to run yourself. `--detach` starts it under `nohup` in its own
process group, so it outlives the shell that started it, and records it:

```sh
aih dispatch worker --detach           # prints the pid
aih dispatch reviewer --detach         # after an integrate --next that exited 10
aih status                             # the row for that todo: dispatched, role, pid, how long
aih log fix-something                  # everything that happened to one todo
```

A headless agent needs whatever flag its CLI takes to act without prompting.
That flag goes in `AI_HARNESS_AGENT_CMD`, not in the harness.

- `AI_HARNESS_MAX_WORKERS` caps active claims. `claim` refuses past it.
- Two racers on one todo: git's ref lock lets exactly one create the branch.
- Two todos with overlapping `Touches`: `claim` refuses the second while the
  first is active, and `plan` names the path they meet on.
- Gates in `AI_HARNESS_EXCLUSIVE_GATES` hold a global resource. A lock serializes
  them across every worktree, so parallel workers queue instead of colliding.
- A crashed worker keeps its claim. `aih abandon <todo>` releases it.


## Todo

Work that needs doing lives in `todo/`, one file per item. `ls todo/` is the
backlog — if a file is there, the work is open.

### Filename is the branch name

`todo/<prefix>-<short-kebab>.md` → branch `<prefix>/<short-kebab>`.

```
todo/feat-pane-resize.md    →  git switch -c feat/pane-resize
todo/fix-empty-desc-line.md →  git switch -c fix/empty-desc-line
```

Same prefixes as commits, declared in `AI_HARNESS_PREFIXES`. No numbers: todos
have no order, and two agents filing at once would race for the same one.

### Shape

```markdown
# <prefix>: <short title>

- **Priority:** high | medium | low
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

Every box must be checkable from the worker's own worktree; `aih <verb> --help`
says where a verb runs. A box that needs the trunk checkout is a human's and
says so: prefix it `human:`, or rewrite it as a static property of the diff
that a worker can check directly.

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

File it into `todo/new/`, not `todo/` directly: only `todo/` is the backlog,
and nothing under `todo/new/` is claimed, planned, or run until a human moves
it there by hand — `git mv todo/new/<file>.md todo/`. Name the file with one
of the project's declared `AI_HARNESS_PREFIXES`; what each one means is that
project's `AGENTS.md`, not this one.

Filing is not prioritizing. The maintainer decides what gets picked up.

## Common tasks

- Open a trunk: `aih init`
- See the backlog and what would run: `aih plan`
- See what is running or ran: `aih status`, `aih log`
- File a todo: a file in `todo/new/`
- Take one: `aih claim`
- Work a set unattended: `aih run`
- Hand off: `aih submit`
- Judge: `aih integrate`
- Retire a trunk: a pull request from the trunk to `main`, then
  `git worktree remove` and `git branch -d`; there is no verb
  (adr-2026-09-29-init-opens-a-dated-trunk-worktree)
