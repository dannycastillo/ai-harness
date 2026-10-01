# doc: copy edit the README and fill its gaps

- **Priority:** medium
- **Touches:** README.md
- **Blocked by:** —

## Goal
`README.md` reads cleanly, carries a passing CI badge, and covers gates,
protected paths and parks, the cost warning, and uninstalling, without
losing the shape the maintainer gave it on 2026-09-30.

## Why
The maintainer rewrote the README by hand as a developer quickstart
(commit `doc: rewrite the README as a quickstart...` on the trunk). The
prose has trailing whitespace and some grammar slips, and the rewrite
dropped a few things a first-time user needs before they run agents
against their subscription.

## Notes
Keep the content and order largely as they are. This is a copy edit plus
five additions, not a second rewrite. Brevity throughout: each new
section is a short paragraph or a handful of bullets, no more.

Copy edit:
- Remove trailing whitespace (`grep -nE ' +$' README.md` finds three
  lines today) and add the missing final newline.
- Fix grammar and punctuation; keep the maintainer's voice and first
  person where it appears ("I recommend...").
- Do not "correct" two things the README says ahead of the code: Sonnet
  as the default agent, and the `aih-YYYYMMDD` trunk name. Both land with
  `todo/feat-init-flow-cleanup.md`, which also reserves `README.md`, so
  the two todos serialize; whichever goes second rebases over the other.

Additions, in README order:

1. **CI badge** under the title, linking to the workflow run list.
   The workflow is `.github/workflows/ci.yml`, named `ci`, and runs on
   push and pull request:
   ```markdown
   [![ci](https://github.com/dannycastillo/ai-harness/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/dannycastillo/ai-harness/actions/workflows/ci.yml)
   ```
2. **Cost warning**, promoted from the `!!!` line under Starting a Run to
   a GitHub-rendered callout (`> [!WARNING]`) placed before the first
   `aih run` command. Keep its meaning: parallel agents multiply usage,
   the user monitors their own plan, the harness guarantees no cap. Drop
   the shouting caps and the `!!!`; the callout carries the weight. Point
   at `AI_HARNESS_MAX_WORKERS` as the one knob that bounds it.
3. **Gates**, a new section after Starting a Run, titled for the reader
   (for example "Defining your own checks"). Say, from `verbs/gate.sh`
   and `lib/gate.sh`:
   - Gates are shell functions in `.ai-harness.conf`: `ai_harness_gate_<name>`
     plus `AI_HARNESS_GATE_TOOLS_<name>` naming what must be on `PATH`.
     `aih init` detects a stack and writes a starting set.
   - Two lists. `AI_HARNESS_QUICK_GATES` is the commit gate: a worker runs
     `aih gate --quick` before every commit. `AI_HARNESS_GATES` is the
     merge gate: `aih submit` runs `aih gate --full` before handing off,
     and `aih integrate` runs it again on the merged result before the
     merge is kept. A red merge gate parks; it never merges.
   - A declared gate whose tool is missing stops with exit 4 and is never
     skipped. Declare fewer gates rather than one that cannot run.
   - One short example, this repo's own `shellcheck` gate from
     `.ai-harness.conf`, is enough.
4. **Protected paths and parks**, a short section near Gates. From
   `lib/check.sh`:
   - `AI_HARNESS_PROTECTED` is a list of globs in `.ai-harness.conf`.
     Unset, it is `AGENTS.md`. `.ai-harness.conf` is always protected and
     cannot unprotect itself. Listing a protected path in a todo's
     `Touches` reserves it against other workers but does not lift the
     protection.
   - "Parks" means the harness stops short of merging and leaves the
     branch and worktree intact for a human: a protected path, a red
     merge gate, a commit subject outside the prefixes, a dirty trunk. The
     queue moves on. `aih status` shows the parked row and its reason;
     the human merges by hand or rejects. A park is the harness working,
     not failing.
5. **Uninstall**, the last section of the file, after Removing your
   trunk. Three parts, each one command or two:
   - Brew: `brew uninstall ai-harness`, optionally
     `brew untap dannycastillo/tap`.
   - Curl install (`install.sh` lines 87 to 89): remove
     `${XDG_DATA_HOME:-$HOME/.local/share}/ai-harness` and
     `~/.local/bin/aih`.
   - From one repo: delete `.ai-harness.conf`, `todo/`, and the state dir
     `$(git rev-parse --git-common-dir)/ai-harness`, plus the worktree
     root once it is empty.

Check every claim against the verb it describes before writing it;
`aih <verb> --help` is the per-verb truth. Link to `aih protocol` rather
than restating anything the protocol already says at length.

## Done when
- [ ] `grep -nE ' +$' README.md` prints nothing and the file ends with a newline
- [ ] a CI badge for the `ci` workflow sits under the title
- [ ] the cost warning is a `> [!WARNING]` callout before the first `aih run` command and names `AI_HARNESS_MAX_WORKERS`
- [ ] a gates section explains `ai_harness_gate_<name>`, the quick list as the commit gate, and the full list as the merge gate run by `submit` and `integrate`
- [ ] a short section defines `AI_HARNESS_PROTECTED`, says `.ai-harness.conf` is always protected, and defines "parks"
- [ ] uninstall instructions for brew, the curl install, and a single repo are the last section of the file
- [ ] the existing sections keep their order and substance; Sonnet-by-default and `aih-YYYYMMDD` are left as written
- [ ] `aih gate` passes
