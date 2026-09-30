# feat: every verb answers --help

- **Priority:** high
- **Touches:** bin/aih, lib/common.sh, verbs/*, NEW docs/adr-2026-09-29-*.md, docs/adr-2026-09-26-the-protocol-ships-with-the-tree.md
- **Blocked by:** —

## Goal
`aih <verb> --help` prints that verb's documentation from the verb file's
own header, from any directory, and `aih help` tells an agent that is
where to look.

## Why
Two verbs in twenty-one have a usage string and none answers `--help`. A
verb's behaviour has had nowhere to be written down except
`roles/protocol.md`, so five of that file's six edits since 2026-09-26
were one verb changing (what `check` refuses, when `plan` steps aside,
what a `run` contains). Every such change reserved the shared file and
serialized the backlog. Documentation that lives in the verb file changes
with the verb and reserves nothing else.

## Notes
- The header is the help. Each `verbs/<verb>.sh` opens with a comment
  block: line 1 stays `# <verb> — <one line>` (`verbs/help.sh` reads it
  with `sed -n '1s/^# [a-z-]* — //p'`), then `#`, then
  `# usage: aih <verb> [...]`, then `#` and a few lines: what it reads,
  what it writes, what it refuses, where it runs (anywhere, the trunk
  checkout, or a claim's worktree), and any exit code beyond 0/1/2 it
  uses. Under fifteen lines. The block ends at the first line that is not
  a comment.
- `lib/common.sh`: `ai_harness_verb_help <verb>` prints that block with
  the leading `# ` stripped; `ai_harness_usage_line <verb>` prints only
  the `usage:` line. `verbs/dispatch.sh` and `verbs/role.sh` drop their
  `_usage` strings and die with the usage line, so the text has one copy.
- `bin/aih`: after the `verb_file` check and before the `help | version`
  case, `case ${1:-} in -h | --help) ai_harness_verb_help "$verb"; exit
  "$EX_OK" ;; esac`. Placed there it needs no repository and no config,
  like `help`.
- Content comes from the verb's code, the README's "Verbs, by owner"
  table, and the sentences about that verb in `roles/protocol.md`. Copy,
  do not cut: trimming the protocol is
  `doc-move-verb-facts-out-of-the-protocol`, and the README is
  `doc-readme-defers-to-help-and-protocol`.
- Header comments that explain the design to a reader of the code
  (`help.sh`'s "globbed rather than declared", `init.sh`'s per-machine
  note) are not help. Move each below the block, next to what it explains
  (AGENTS.md, Comments). The block is for the person running the verb.
- `verbs/help.sh`: one line after the verb list, before the relocatable
  paragraph: `aih <verb> --help` says what one verb reads, writes and
  refuses, and where it runs. The `aih protocol` line is
  `feat-protocol-is-its-own-verb`'s.
- ADR, `docs/adr-2026-09-29-help-lives-in-the-verb.md`: a fact has one
  home. A verb's behaviour is its header, printed by `--help`; the
  protocol holds only rules two or more verbs or roles share; the README
  holds install and first run and points at the two verbs. Name the verbs
  as `aih protocol` and `aih role <worker|reviewer>`, which supersedes
  only the verb-naming line of
  adr-2026-09-26-the-protocol-ships-with-the-tree; add the `Superseded
  by:` back-pointer there and say it is the naming line only. Alternatives
  to record: a docs tree per verb (a second file to reserve, and it drifts
  from the code); an MCP server (a second interface tracking every verb
  plus per-platform config, against ADR-10's agent-agnostic loop); one
  protocol file holding everything (the measured serialization above).
- Runs alone: `verbs/*` reserves every verb. Keep the diff to headers,
  the two helpers, the launcher case and the ADR.

## Done when
- [ ] from a directory that is not a git repository, `for v in verbs/*.sh; do ./bin/aih "$(basename "$v" .sh)" --help; done` exits 0 for every verb
- [ ] every verb's `--help` opens with the same one-liner `aih help` shows for it, has a `usage:` line, and says where it runs
- [ ] `aih help` ends with the `--help` pointer
- [ ] no verb file defines `_usage`; usage errors print the header's usage line
- [ ] design comments moved out of the header blocks sit next to the code they explain
- [ ] the ADR exists and adr-2026-09-26-the-protocol-ships-with-the-tree carries the back-pointer
- [ ] `aih gate` passes
