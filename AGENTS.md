# AGENTS.md

Working agreements for this repo. Minimal on purpose — sections get added when
we hit something actually worth writing down, not in anticipation.

The rules the harness enforces — todos, `Touches`, working in parallel — are
`aih role protocol`. This file holds what is this repo's, including how it
names branches and writes commits.

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

### Before every commit

```sh
aih gate --quick
```

It must pass. What it runs is declared in `.ai-harness.conf` (ADR-09), so this
file names no language. Don't commit over a failure — fix it or report it. Say
in your summary that it ran and what it said, so the check is visible rather
than assumed.

### Trunk is written only by `aih integrate`

Two roles, and the session that writes a diff never reviews it (ADR-10):

- A **worker** finishes by running `aih submit`. It never merges, never
  pushes, and never runs `git merge`.
- A **reviewer** verifies the packet `aih integrate --next` prints and
  finishes by running `aih integrate --continue` with a verdict. The verb
  merges; the reviewer never does.

`integrate` merges with `--no-ff`, so there is a merge commit even when `main`
hasn't moved. A fast-forward would splice the branch's commits into `main` as a
flat line and lose the fact that they shipped as one unit; the merge commit
keeps that grouping, so `git log --first-parent main` reads as a list of
changes rather than a list of keystrokes.

Anything the verbs stop on — a park, a red gate, a path outside `Touches` — is
a human's to resolve, and a human merging by hand is the one exception to the
rule above. `aih log` marks such a merge `by hand`, because it carries no
trailers.

Never push a branch, merge, or force-push anything without being asked. The
one exception is `aih integrate` pushing the trunk after a green merge when
`.ai-harness.conf` sets `AI_HARNESS_PUSH_TRUNK` to `yes`: the conf is the asking.

## ai-harness

A worker that changes a verb runs `./bin/aih` to see it working; the
reviewer's `integrate` runs the installed copy.

## Architecture decisions

Decisions about the project's direction live in `docs/` as Architecture
Decision Records — one file per decision, named by the date it was made.

### Read them before starting work

`ls docs/` and read the titles. Read in full any ADR whose subject touches what
you're about to change.

If your intended approach contradicts an accepted ADR, **stop and say so**.
Don't quietly follow the ADR against the request, and don't quietly break it.
The conflict is the useful signal: either the request is the better idea and the
ADR should be superseded, or the ADR has a reason behind it that the request
didn't account for. Both are worth a sentence before any code gets written.

### When to write one

Write an ADR when a decision would be expensive to reverse — someone later would
have to *undo* it rather than edit around it — or when a reasonable person would
have chosen the other option. Swapping a dependency, deciding where data lives,
fixing the shape of a package's public API, deciding what the tool deliberately
won't do.

Don't write one for: adding a flag, fixing a bug, refactoring inside a file, or
anything the code already makes obvious. If a reader could recover the reasoning
by reading the diff, the diff is the record.

Unsure? Ask — guessing wrong is cheap in one direction and expensive in the
other.

### File shape

`docs/adr-YYYY-MM-DD-short-kebab-title.md`, dated the day it is written.
Two authors on one day pick different titles; the same title on the same day
is the same path, which git reports as a conflict instead of merging silently.
That is the whole reason for the date: sequential numbers were tried and two
branches can each add the next one with no conflict at all.

Refer to an ADR by its file name without the directory and extension. The
first ten are numbered `ADR-01` to `ADR-10` and keep those names. ADR-01 to
ADR-06 are about wut and stay in `dannycastillo/wut-command`.

```markdown
# ADR YYYY-MM-DD: Title

- **Status:** Accepted
- **Date:** YYYY-MM-DD

## Context
What was true before. What forced a choice.

## Decision
What we do, present tense.

## Alternatives considered
Each option, and the one reason it lost.

## Consequences
What this makes easy, what it makes hard, what we now maintain. Costs
included.
```

An ADR that accompanies a change rides on the same branch as its own `doc:`
commit, so the decision and the work are reviewable together but separable.

### Tone

Write for scanning. State the facts and the reasons; don't argue them.

- Bullets over paragraphs. Short sentences. Present tense.
- One line per reason. No justifying, no persuading, no hedging.
- Prefer specifics — versions, function names, file paths, measured numbers —
  over adjectives.
- Don't restate the Decision inside the Consequences.
- If a reason needs a paragraph to defend, the decision isn't settled. Settle
  it, then record the outcome.

One screen per ADR. Longer than that means it's covering more than one
decision — split it.

### ADRs are append-only

Never rewrite the Decision of an accepted ADR. A record you edit is no longer a
record of what you decided — it's a record of what you currently think, and the
code already tells you that.

To change course, write a new ADR carrying `**Supersedes:** <old name>`, and
add a `**Superseded by:** <new name>` line to the old one's status block.
Adding that back-pointer is the only edit an accepted ADR ever takes. List the
old file in `Touches`, so two branches superseding it serialize.

## Comments

A comment earns its place when the code is surprising: a workaround, a measured
constant, an upstream bug, an invariant two files share, a non-obvious ordering.
The things a reader would otherwise "fix".

Everything else is noise. The reasoning behind a design goes in the commit
message or an ADR, where it cannot drift out of sync with the code it describes,
and where this repo already expects it in full.

- Default to none. The code says what it does; a comment says why it looks wrong.
- Keep a short header on each script — what it is, in a line or two.
- A comment longer than the code it describes is arguing a design. Move it.
- Never restate the line below, number steps, or leave commented-out code.

This governs source files only. Explanations in review and in chat are a
different thing and stay as long as they need to be.
