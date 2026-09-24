# ADR 2026-09-24: Protected paths live in config

- **Status:** Accepted
- **Date:** 2026-09-24

## Context
- `check` hard-stopped any diff to `AGENTS.md`, `.ai-harness.conf` or
  `ai-harness/*`, whatever the todo's `Touches` declared. The list was in
  `lib/check.sh`, not in config.
- In a project using the harness that is right: agents should not merge edits
  to the rules and the tool that govern them.
- In the harness's own repo nearly every todo touches `ai-harness/`, so every
  branch parked `protected-path` and `aih run` could merge nothing.
- `AI_HARNESS_PROTECTED` existed but was read only for paths outside
  `Touches`, which `undeclared-path` already stopped. It changed a code's
  name and protected nothing.

## Decision
- `AI_HARNESS_PROTECTED` is the list of hard-stop globs. Declaring one in
  `Touches` reserves it; it still parks.
- Unset, it is `AGENTS.md ai-harness/*`. Empty, it protects nothing extra.
- `.ai-harness.conf` is protected unconditionally, as ADR-09 requires.
- This repo sets `AGENTS.md .github/workflows/*`: the reviewer may merge
  harness code; rules and CI stay a human's.

## Alternatives considered
- **Keep the hardcoded list** — the harness cannot build itself; every change
  is a hand merge.
- **A second variable that unprotects** — two lists to reconcile for one
  question.
- **Run integrate from a copy of the harness** — solves a script-rewrite hazard
  that does not exist (git replaces files by new inode); governance was the
  real reason for the stop.

## Consequences
- A branch cannot weaken the `check` that judges it: `integrate` runs trunk's
  copy. A weakened harness applies from the next merge on, after a reviewer
  passed it.
- In this repo a reviewer agent now merges harness changes that a human used
  to read. The reviewer's Done-when verification is the only judgment on them.
- Loosening the list is a config edit, so it always goes through a human.
