# ADR 2026-09-29: Help lives in the verb

- **Status:** Accepted
- **Date:** 2026-09-29
- **Supersedes:** adr-2026-09-26-the-protocol-ships-with-the-tree, the verb-naming line only

## Context
- Two verbs of twenty-one had a usage string; none answered `--help`.
- A verb's behaviour had nowhere to live but `roles/protocol.md`. Five of
  that file's six edits since 2026-09-26 were one verb changing.
- Each such edit reserved the shared file and serialized the backlog.

## Decision
- A fact has one home.
- A verb's behaviour is the comment block that opens `verbs/<verb>.sh`,
  printed by `aih <verb> --help` from any directory.
- The protocol holds only rules two or more verbs or roles share.
- The README holds install and first run, and points at `aih protocol` and
  `aih role <worker|reviewer>`.
- The verbs are named `aih protocol` and `aih role <worker|reviewer>`. This
  replaces `aih role <protocol|worker|reviewer>` in
  adr-2026-09-26-the-protocol-ships-with-the-tree, and nothing else there.

## Alternatives considered
- **A docs tree per verb** — a second file to reserve, and it drifts from the code.
- **An MCP server** — a second interface tracking every verb, plus
  per-platform config, against ADR-10's agent-agnostic loop.
- **One protocol file holding everything** — the serialization measured above.

## Consequences
- A change to a verb edits one file and reserves nothing else.
- Every verb file opens with a block a reader can run: one-liner, `usage:`
  line, what it reads, writes and refuses, where it runs.
- Design comments sit below the block, beside the code they explain.
- `aih protocol` does not exist yet; the naming is decided here and built
  by a later change.
