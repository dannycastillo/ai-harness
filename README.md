# Welcome to AI Harness

A minimal (POSIX sh + git) tool to run concurrent agentic tasks on a single machine or server. Designed to be AI and language agnostic. Simply add markdown files into a `todo/` directory and agents will follow your instructions and project conventions.

Each agent gets its own git worktree and merges into a `trunk` branch defined by you. 

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

In the repo you want to work:

```sh
aih init
```

First step is to configure the `trunk`. This is the branch and worktree where the agents will automatically merge their code. The `aih init` command creates your `trunk` and writes an `.ai-harness.conf` file at the root of your project.

Once you have your trunk branch and worktree, cd into it and run `aih doctor` to ensure it was setup correctly.

ai-harness uses Claude Sonnet as its default agent out of the box. You can customize the agent you want aih to use by updating the 
`AI_HARNESS_AGENT_CMD` in the `.ai-harness.conf` file.

The aih tool is documented to work well with interactive agent sessions. So you can also ask your agent "Init a new aih trunk for me called my-first-aih-test" and it should be able to get you going.


## Writing todo files

Agents pick up work from markdown files written to a `todo/` directory in the root of the project. At a very minimum a todo file should contain a `Priority`, a `Touches`, and a `Done when` checklist. These are needed to facilitate concurrency and enable the automated review.

I recommend providing more detail in each todo. Think of these as context to help your AI worker complete the task. Here is an example of what I recommend. See more info at `todo/README.md`.


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

An interactive AI agent can also help you. Ask it to "File a new aih todo to do some thing". The more detail, the more likely you are to get a result you expect.

Only markdown files in the top level of the todo directory will be picked up by AI workers, e.g. `todo/*.md`. You can add tickets into subdirectories that you want to file but are not ready to be worked on, e.g. `todo/backlog/*.md` or `todo/new/*.md`.


## Starting a Run

An `aih run` will look at the files in the todo directory and kick off `ai-workers` to complete each task. Each worker is its own non-interactive AI session and the parallelism is defined by your `.ai-harness.conf` file as well as how much overlap there is in the Touches field of each todo. 

Once you have your todos ready to go, you can run them all:

```sh
aih run --all
```

Or you can run a specific set of them:

```sh
aih run todo-file-1 todo-file-2
```

You can then monitor the run by calling `aih status` or `aih log` from within your trunk directory.

!!! WARNING - running parallel agents will lead to much higher usage against your AI tool subscription plan. YOU ARE RESPONSIBLE FOR MONITORING YOUR USAGE. AI HARNESS TOOL DOES NOT PROVIDE ANY GUARANTEED PROTECTION AGAINST EXCESSIVE USAGE. !!!


## Removing your trunk

Once you have merged your trunk into `main` or decided to discard the work, you can simply delete the worktree and branch.

For example if your trunk was created by `aih init`:

```sh
git worktree remove <worktree-root>/aih-YYYYMMDD
git branch -d aih-YYYYMMDD
```