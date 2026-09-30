# feat: aih protocol prints the shared rules

- **Priority:** high
- **Touches:** NEW verbs/protocol.sh, bin/aih, verbs/role.sh, verbs/dispatch.sh, verbs/plan.sh, verbs/help.sh, roles/worker.md, roles/reviewer.md, adapters/*, templates/todo-README.md, todo/README.md
- **Blocked by:** feat-every-verb-answers-help

## Goal
`aih protocol` prints the shared rules from any directory, `aih role
worker` and `aih role reviewer` print those rules followed by the role,
and nothing in the tree says `aih role protocol`.

## Why
The protocol is not a role; it is the preamble every role reads. Filing
it under `role` made a reader ask what kind of agent a "protocol" is, and
made every boot prompt and adapter say two commands where one would do.
An agent asking what this tool is should be able to run one verb, from
anywhere, and get the whole answer.

## Notes
- `verbs/protocol.sh`, new: a header in the shape
  feat-every-verb-answers-help set, then
  `cat "$AI_HARNESS_HOME/roles/protocol.md"`. The file stays in `roles/`:
  it is what every role begins with, and moving it is churn with no
  reader. `adr-2026-09-29-help-lives-in-the-verb` already names the verb;
  no new ADR.
- `bin/aih`: add `protocol` to the `help | version` case. It reads only
  the tree, so it needs no repository and no config, which is what lets a
  session standing on `main` ask how the tool works.
- `verbs/role.sh`: accepts `worker | reviewer`; prints
  `roles/protocol.md`, a blank line, then the role file. `protocol` as an
  argument is a usage error whose message names `aih protocol`.
- `verbs/dispatch.sh`, both `_prompt` strings: "Then run `aih role
  worker` and follow it" and the reviewer equivalent. Nothing else in the
  prompts changes.
- `adapters/claude-code/skills/*/SKILL.md` and `adapters/cursor/rules/*.mdc`:
  the same one-command change. `adapters/README.md`'s "the protocol, the
  role doc" stays true and stays.
- `templates/todo-README.md` and this repo's `todo/README.md` carry the
  same text; change both: `aih protocol` for the rules.
- `verbs/plan.sh`, the empty-backlog line: `aih protocol says how to file
  one`.
- `roles/worker.md` and `roles/reviewer.md` open with "The rules are in
  `AGENTS.md`", which stopped being true on 2026-09-26. The rules are now
  printed directly above them: say so, and point the sequence's
  references (**Picking one up**, "`AGENTS.md` says to") at the protocol.
  `AGENTS.md` remains where the project's own conventions are.
- `verbs/help.sh`: after the `--help` line, one more: `aih protocol` is
  the shared rules, todos, `Touches`, branches and roles; read it before
  running anything.
- Not this todo: README.md (`doc-readme-defers-to-help-and-protocol`).
  `AGENTS.md` line 7 says `aih role protocol` and is a protected path;
  the maintainer changes it by hand once this merges.

## Done when
- [ ] from a directory that is not a git repository, `./bin/aih protocol` prints `roles/protocol.md`
- [ ] `./bin/aih role worker` prints the protocol and then `roles/worker.md`; the same for `reviewer`
- [ ] `./bin/aih role protocol` exits 2 and its message names `aih protocol`
- [ ] `grep -rn 'role protocol' bin lib verbs roles adapters templates todo/README.md` finds nothing
- [ ] both boot prompts in `verbs/dispatch.sh` name exactly one `aih role` command
- [ ] neither role doc says the rules are in `AGENTS.md`
- [ ] `./bin/aih help` names `aih <verb> --help` and `aih protocol`
- [ ] `aih gate` passes
