# AI Harness

One todo, one branch, one worktree. Trunk is written only by a merge. The
command is `aih`, short for ai-harness, and it is the only command.

The harness lets several agents work one repo's backlog at once without
landing in the same file. It is plain POSIX sh plus git, and nothing else.
The repo's rules stay in `AGENTS.md`; the harness enforces them mechanically.
Design: ADR-10 (a shell loop schedules two roles) and ADR-09 (the gate lives
in config).

- Working agreements for this repo: [`AGENTS.md`](AGENTS.md)
- Decisions: [`docs/`](docs/)

This repo was split out of
[`dannycastillo/wut-command`](https://github.com/dannycastillo/wut-command),
another project of the author's, where the harness was originally built.

## Quickstart

Install, once per machine:

```sh
brew install dannycastillo/tap/ai-harness
```

```sh
curl -fsSL https://raw.githubusercontent.com/dannycastillo/ai-harness/main/install.sh | sh
```

In the repo you want it to work:

```sh
aih init
```

It asks where finished work merges. The default is a new branch and worktree,
`ai-harness-YYYYMMDD` beside your repo; `init` commits the config there and
never touches the branch you have checked out. It then detects the stack,
prints the `.ai-harness.conf` it would write, and stops for a `y`. Move to the
new trunk:

```sh
cd ../<project>-worktrees/ai-harness-YYYYMMDD
aih doctor
```

Open the config it wrote and uncomment `AI_HARNESS_AGENT_CMD`, pointing it at
your agent CLI's non-interactive flags — that's the one line `init` leaves for
you to fill in, and it is yours to commit on the trunk.

The other answer, `aih init --trunk <branch>`, makes the branch checked out
here the trunk. It writes the files and commits nothing, so you commit them;
and while `integrate` merges there, that checkout must stay clean, or every
merge parks. Run from any other checkout, `aih` says which directory to use.

Write one file under `todo/`, in the shape `todo/README.md` shows, then:

```sh
aih run --all
```

A run is the set of todos present when it starts. A todo filed into `todo/`
while it runs is listed by `aih status` under `outside this run` and waits for
the next one.

What you'll see: a worktree per todo, and, for each one that passes review, a
merge on trunk carrying `AI-Harness-*` trailers for the todo, the worker, and
the gate. Anything a human needs to look at — a protected path, a red gate, a
stale check — parks instead of merging; `aih status` shows what's still
running, `aih log` shows what already happened.

Agents run unattended and answer no prompts, inside the worktree `aih claim`
cut for them — that worktree is the sandbox, not your working copy. Point
`AI_HARNESS_AGENT_CMD` only at an agent you trust with that, because
`.ai-harness.conf` is sourced as shell, by every verb, so whatever it names
runs with your own permissions.

## Removing it

A trunk merged into `main` is closed by removing what `init` made:

```sh
git worktree remove <worktree-root>/ai-harness-YYYYMMDD
git branch -d ai-harness-YYYYMMDD
```

To drop the harness from a repo altogether, also delete
`$(git rev-parse --git-common-dir)/ai-harness`, the coordination state, and
the worktree root once it is empty. `aih init` opens the next trunk.

## Status

Partly built. `aih help` lists what your copy has.

- Every verb in the tables below is built, and all three role docs exist:
  `aih role protocol`, `worker`, `reviewer`.
- `AGENTS.md` names the two roles and no language. Trunk is written only by
  `integrate`, as a rule rather than a mechanism: a merge made by hand shows
  in `aih log` as `by hand`, since it carries no trailers.
- Not yet lifted into another repo. The adapters are in `adapters/`.

## Setup

The tree is relocatable and installs once per machine; a repo holds only
`.ai-harness.conf` and `todo/`. Two ways to install it:

```sh
brew install dannycastillo/tap/ai-harness
```

```sh
curl -fsSL https://raw.githubusercontent.com/dannycastillo/ai-harness/main/install.sh | sh
```

For a checkout you're developing against, point a launcher at this tree
directly instead:

```sh
cat >~/.local/bin/aih <<'EOF'
#!/bin/sh
exec "${AI_HARNESS_HOME:-<path to this tree>}/bin/aih" "$@"
EOF
chmod +x ~/.local/bin/aih
aih doctor --selftest
```

`aih doctor` prints that block with this tree's path filled in.
`bin/aih` resolves symlinks before locating its tree, so the launcher works
whether it's a plain exec, a symlink, or a package manager's stub.
`AI_HARNESS_HOME` overrides which tree runs — how a developer picks a
checkout's copy over the installed one. Agents the loop starts do not need
it: `run` puts the running copy's own `bin` first on their PATH.

- A repo the harness has never seen: `aih init` detects the stack, writes
  `.ai-harness.conf`, and creates `todo/`, including its `todo/new/` inbox —
  the only place an agent files a todo without a human moving it into the
  backlog by hand. It always prints the config first and stops for a `y`
  unless given `--yes`.
- `doctor` checks the state dir, trunk, the worktree root, and every declared
  gate's tools. It changes nothing unless given `--repair`, which rebuilds
  claims from git.

## The two roles

A different session plays each role. The session that writes a diff never
reviews it. Each role ends its work by running one verb, and the verb does
every write to shared state: no agent runs `git merge`.

| Role     | Does                                                                  | Never                                          |
| -------- | --------------------------------------------------------------------- | ---------------------------------------------- |
| worker   | claims one todo, works it in its own worktree, rebases, `submit`s     | merges, or edits outside its `Touches`         |
| reviewer | verifies a packet's **Done when**, then `integrate --continue`s       | rebases a branch, resolves a conflict, or cleans trunk |

A human owns everything the two roles stop on: parks, stale locks, pauses.

## Verbs, by owner

`*` marks a verb that is not built yet.

| Owner      | Verb                        | Does                                                          |
| ---------- | --------------------------- | ------------------------------------------------------------- |
| worker     | `claim <todo>`              | cuts the branch and worktree from trunk; prints the path      |
|            | `path <todo>`               | prints a claim's worktree, for `cd "$(aih path <todo>)"`  |
|            | `gate --quick` / `--full`   | runs the declared checks, one line each                       |
|            | `submit`                    | requires a clean tree and a green `gate --full`, then queues  |
|            | `abandon <todo>`            | gives the claim back; refuses a dirty tree or a live agent unless `--force` |
| reviewer   | `check`                     | read-only diff check: paths against `Touches`, hard stops     |
|            | `integrate`                 | baseline gate, packet, merge, post-merge gate; or park        |
| human      | `init [--yes] [--force]`    | writes `.ai-harness.conf` and `todo/` for a repo with neither  |
|            | `status`                    | the run in progress or the last one, then every todo outside it |
|            | `doctor [--repair]`         | asserts the setup; `--repair` rebuilds claims from git        |
|            | `unlock <name> --force`     | releases a lock whose holder is dead                          |
|            | `plan`, `dispatch`          | says what can run and why; claims one and starts an agent (`--print` shows the boot prompt without claiming) |
|            | `log [<todo>]`              | events and merge trailers, one timeline                       |
|            | `run [<todo>...]`           | works a set of todos unattended, until idle or a stop         |
|            | `pause`, `resume`           | stops new claims; queued work still merges; lifts it          |
|            | `stop [--agents]`           | kills the loop and every agent; claims and trees stay         |
| anyone     | `help`                      | lists the verbs in this copy                                  |
|            | `version`                   | prints the tree's `VERSION`                                    |
|            | `role protocol\|worker\|reviewer` | prints that role doc from the tree                       |

Exit codes: `0` ok, `1` failed, `2` usage, `3` paused, `4` the environment
cannot run the gate, `10` judgment needed.

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

## Stop conditions, and one worked example

A merge is automatic only when every check passes. Anything else **parks**: the
branch stays intact, the queue moves on, and a human decides. A park is the
harness working, not failing.

`doc-add-license` always parks. Its todo:

```
- **Touches:** LICENSE, THIRD_PARTY_LICENSES.md, AGENTS.md
```

- It must edit `AGENTS.md` to remove a personal name, so it declares it.
- `AGENTS.md` is in `AI_HARNESS_PROTECTED` by default, which makes it a hard
  stop in `check`. Declaring it in `Touches` does not lift that; it only
  reserves the file against other workers.
- So `check` reports `protected-path` and the branch parks, every time.
- Reason: `AGENTS.md` holds the rules every agent obeys. An agent that edits
  the rules must not also be able to merge the edit.
- Resolution: a human reads the diff and merges it by hand.

Other hard stops, all by design: `.ai-harness.conf`, any other
`AI_HARNESS_PROTECTED` path, a commit subject outside the four prefixes, a red
trunk before the merge, a red gate after it, and a dirty trunk checkout. Nothing in that list names a path that is not a todo, the
config, or `AI_HARNESS_PROTECTED`: the harness knows nothing about the
project's own conventions.

## Configuration

Everything project-specific lives in `.ai-harness.conf` at the repo root, sourced
as POSIX sh. Nothing in `bin/`, `lib/`, or `verbs/` knows the project's language.
A Go project's config, for example:

```sh
AI_HARNESS_PROJECT="wut"
AI_HARNESS_TRUNK="main"
AI_HARNESS_WORKTREE_ROOT="../wut-command-worktrees"   # relative to the main worktree; see Worktree layouts
AI_HARNESS_PREFIXES="feat fix doc chore"
AI_HARNESS_MAX_WORKERS=3
AI_HARNESS_PROTECTED="AGENTS.md .github/workflows/*"
AI_HARNESS_PUSH_TRUNK="yes"

AI_HARNESS_GATES="build vet fmt test shellcheck shellsize"
AI_HARNESS_QUICK_GATES="build vet"
AI_HARNESS_EXCLUSIVE_GATES="test"

ai_harness_gate_build() { go build ./...; }
AI_HARNESS_GATE_TOOLS_build="go"
```

### Worktree layouts

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
- `.ai-harness.conf` is always a hard stop in `check`, so an agent cannot
  loosen the gate and merge the change. The config cannot unprotect itself.
- `AI_HARNESS_PROTECTED` lists globs that park for a human even when a todo
  declares them. Unset, it is `AGENTS.md`; set it to add to that or to free
  a path.
- `AI_HARNESS_PUSH_TRUNK="yes"` pushes the trunk to its upstream, fast-forward
  only, after every green merge. Unset or `no`: the merge stays local and a
  human pushes it. `aih init` sets it from whether the trunk already tracks a
  remote. A rejected push warns and leaves the merge on trunk; `aih status`
  and `aih doctor` show an ahead trunk either way.

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

## Conventions for the harness's own code

- **POSIX sh only.** macOS ships bash 3.2.57, so no arrays and no `mapfile`,
  and a lifted copy may run under dash.
- **No shell file over `AI_HARNESS_SHELL_MAX_LINES` (400).** The `shellsize` gate
  enforces it. A total line budget was tried and dropped: it says nothing about
  whether any one file fits in your head, and it turns every addition into a
  negotiation.
- **`shellcheck -s sh` clean.** The `shellcheck` gate enforces it. Each
  suppression carries its reason inline.
- **Libraries only define functions.** `bin/aih` sources `lib/*.sh` in glob
  order, so anything that runs at source time runs in that order too.
- **No verb registry.** A verb is a file in `verbs/`, and `help` globs
  the directory. Adding a verb edits nothing, so two branches adding verbs do
  not conflict. Line 1 of a verb file is `# <verb> — <description>`, which is
  what `help` prints.

## The honest limit

- On this repo's backlog, max parallelism is six todos, and realistically
  three. Shared files, an `ALL` barrier and `Blocked by` chains serialize the
  rest.
- The backlog empties in a few sessions. The harness does not pay for itself
  on this repo alone.
- It earns its keep as a template: lifted into other repos, with this one as
  the test fixture.
