# doc: trim AGENTS.md to what is this project's

- **Priority:** medium
- **Branch:** doc/trim-agents-md-to-the-project
- **Touches:** AGENTS.md
- **Blocked by:** feat-aih-role.md

## Goal
This repo's `AGENTS.md` holds only rules that are this project's, points at `aih role protocol` for the rest, and has no checksummed block.

## Why
adr-2026-09-26-the-protocol-ships-with-the-tree. Two copies of the
protocol drift; the tree's is the one agents read.

## Notes
- Stays: the ADR section, Comments, the gate line under "Before every
  commit", and `Trunk is written only by aih integrate`.
- Goes: the sections `roles/protocol.md` now carries, and the
  `<!-- ai-harness:begin -->` block.
- Add a short `## ai-harness` section with what is specific here: a
  worker that changes a verb runs `./bin/aih` to see it; the reviewer's
  `integrate` runs the installed copy.
- `AGENTS.md` is protected; this parks for a human. Expected.

## Done when
- [ ] `grep -c 'ai-harness:begin' AGENTS.md` prints 0
- [ ] `AGENTS.md` points at `aih role protocol` once and repeats none of its sections
- [ ] `AGENTS.md` has a `## ai-harness` section
- [ ] `aih doctor` passes
- [ ] `aih gate` passes
