# ADR 2026-09-26: The protocol ships with the tree

- **Status:** Accepted
- **Date:** 2026-09-26

## Context
- A dispatched agent is told to read `AGENTS.md`, then a role doc, then its
  todo. The role docs say "the rules are in `AGENTS.md`".
- The rules they mean are the harness's: the todo shape, the prefixes, what
  `Touches` reserves, the Done-when contract, `submit` and `--escalate`.
  They sit in this repo's `AGENTS.md` next to rules that are only this
  project's, such as the ADR conventions and the comment policy.
- The abandoned installer copied those sections into every adopting repo's
  `AGENTS.md` inside a checksummed block. `doctor` fails when the block is
  edited. The harness's rules were shipped as the user's document.

## Decision
- The portable rules live in the tree as `roles/protocol.md`, beside
  `roles/worker.md` and `roles/reviewer.md`.
- `aih role <protocol|worker|reviewer>` prints one. The boot prompt and
  every adapter say `aih role`, never a path.
- The boot prompt tells an agent: read `AGENTS.md` in full; if it has a
  section headed `## ai-harness`, those instructions extend your role.
  Nothing parses the section. A repo with nothing to add has none.
- There is no checksummed block. `doctor` stops checking for one.
- This repo's `AGENTS.md` keeps only what is this project's and points at
  `aih role protocol` like any other repo.

## Alternatives considered
- **Copy the protocol into each `AGENTS.md`** — drifts per repo, and the
  checksum only detects that it drifted.
- **Put project customizations in `.ai-harness.conf`** — prose for an agent
  in a file sourced as shell.
- **A separate `AI-HARNESS.md` in each repo** — one more file an adopter
  must know about; `AGENTS.md` is where they already write for agents.

## Consequences
- The protocol is versioned with the tree. An adopting repo gets protocol
  changes on upgrade, without an edit to its own files.
- `## ai-harness` is a convention, not a schema. What a project puts there
  is its business; the harness only points at it.
- `AGENTS.md` in this repo shrinks by the sections that move, and the
  Todo section's Done-when rule moves with them.
- `aih role` is one more verb, and the adapters change once to name it.
