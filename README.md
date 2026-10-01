# Welcome to AI Harness

[![ci](https://github.com/dannycastillo/ai-harness/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/dannycastillo/ai-harness/actions/workflows/ci.yml)

A minimal (POSIX sh + git) tool to run concurrent agentic tasks on a single machine or server. It is designed to be AI and language agnostic. Add markdown files into a `todo/` directory and agents will follow your instructions and project conventions.

Each agent gets its own git worktree and merges into a `trunk` branch that you define.

Install the tool, start adding todos, and set your agents to work with `aih run`.

## Quickstart

Install with brew:

```sh
brew install dannycastillo/tap/ai-harness
```

Install with curl:

```sh
curl -fsSL https://raw.githubusercontent.com/dannycastillo/ai-harness/main/install.sh | sh
```

In the repo you want to work in:

```sh
aih init
```

The first step is to configure the `trunk`: the branch and worktree where the agents automatically merge their code. `aih init` creates your `trunk` and writes an `.ai-harness.conf` file at the root of your project.

Once you have your trunk branch and worktree, `cd` into it and run `aih doctor` to check it was set up correctly.

ai-harness uses Claude Sonnet as its default agent out of the box. To change the agent, update
`AI_HARNESS_AGENT_CMD` in the `.ai-harness.conf` file.

`aih` is documented to work well with interactive agent sessions, so you can also ask your agent "Init a new aih trunk for me called my-first-aih-test" and it should be able to get you going.

## Writing todo files

Agents pick up work from markdown files written to a `todo/` directory in the root of the project. At a minimum, a todo file should contain a `Priority`, a `Touches`, and a `Done when` checklist. These enable concurrency and automated review.

I recommend providing more detail in each todo. Think of them as context to help your AI worker complete the task. Here is an example of what I recommend; see `todo/README.md` for more.

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

An interactive AI agent can also help you. Ask it to "File a new aih todo to do some thing". The more detail you give, the more likely you are to get the result you expect.

Only markdown files in the top level of the todo directory are picked up by AI workers, e.g. `todo/*.md`. To file tickets that are not ready to be worked, put them in a subdirectory, e.g. `todo/backlog/*.md` or `todo/new/*.md`.

## Starting a Run

An `aih run` will look at the files in the todo directory and start a worker for each task. Each worker is its own non-interactive AI session, and the parallelism is set by your `.ai-harness.conf` file as well as how much overlap there is in the `Touches` field of each todo.

> [!WARNING]
> Parallel agents multiply your usage against your AI tool subscription plan. You are responsible for monitoring your own usage; the harness guarantees no cap. `AI_HARNESS_MAX_WORKERS` in `.ai-harness.conf` is the one setting that bounds how many agents run at once.

Once your todos are ready, run them all:

```sh
aih run --all
```

Or run a specific set:

```sh
aih run todo-file-1 todo-file-2
```

You can then monitor the run with `aih status` or `aih log` from within your trunk directory.

## Defining your own checks

Gates are the checks a change must pass. Each is a shell function in `.ai-harness.conf`, `ai_harness_gate_<name>`, plus `AI_HARNESS_GATE_TOOLS_<name>` naming what must be on `PATH`. `aih init` detects your stack and writes a starting set. This repo's own:

```sh
AI_HARNESS_GATES="shellcheck shellsize"
AI_HARNESS_QUICK_GATES="shellcheck"

ai_harness_gate_shellcheck() {
	shellcheck -s sh bin/aih lib/*.sh verbs/*.sh
}
AI_HARNESS_GATE_TOOLS_shellcheck="shellcheck"
```

- `AI_HARNESS_QUICK_GATES` is the commit gate: a worker runs `aih gate --quick` before every commit.
- `AI_HARNESS_GATES` is the merge gate: `aih submit` runs `aih gate --full` before handing off, and `aih integrate` runs it again on the merged result before the merge is kept. A red merge gate parks; it never merges.
- A declared gate whose tool is missing stops with exit 4 and is never skipped. Declare fewer gates rather than one that cannot run.

## Protected paths and parks

`AI_HARNESS_PROTECTED` is a list of globs in `.ai-harness.conf`. Unset, it is `AGENTS.md`. `.ai-harness.conf` is always protected and cannot unprotect itself. Listing a protected path in a todo's `Touches` reserves it against other workers but does not lift the protection.

A change to a protected path is not merged. It parks: the harness stops short of merging and leaves the branch and worktree intact for a human. A red merge gate, a commit subject outside your prefixes, or a dirty trunk park too. The queue moves on, and `aih status` shows the parked row and its reason. You merge by hand or reject. A park is the harness working, not failing. See `aih protocol` for the rules in full.

## Removing your trunk

Once you have merged your trunk into `main` or decided to discard the work, you can simply delete the worktree and branch.

For example if your trunk was created by `aih init`:

```sh
git worktree remove <worktree-root>/aih-YYYYMMDD
git branch -d aih-YYYYMMDD
```

## Uninstalling

Brew:

```sh
brew uninstall ai-harness
brew untap dannycastillo/tap        # optional
```

Curl install:

```sh
rm -rf "${XDG_DATA_HOME:-$HOME/.local/share}/ai-harness" ~/.local/bin/aih
```

From one repo, delete the config, the todos and the state dir, plus the worktree root once it is empty:

```sh
rm -rf .ai-harness.conf todo "$(git rev-parse --git-common-dir)/ai-harness"
rmdir <worktree-root>
```
