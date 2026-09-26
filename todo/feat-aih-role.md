# feat: aih role, and the protocol in the tree

- **Priority:** high
- **Branch:** feat/aih-role
- **Touches:** NEW roles/protocol.md, NEW verbs/role.sh, verbs/dispatch.sh, verbs/doctor.sh, adapters/*, README.md
- **Blocked by:** chore-move-the-tree-to-the-repo-root.md

## Goal
`aih role protocol|worker|reviewer` prints a role doc from the tree, the boot prompt and the adapters name the verb, and `doctor` no longer looks for a block in `AGENTS.md`.

## Why
adr-2026-09-26-the-protocol-ships-with-the-tree.

## Notes
- `roles/protocol.md` is the portable text now in this repo's `AGENTS.md`:
  Git workflow's branch and prefix and naming sections, the whole Todo
  section including the Done-when rule, and `Working in parallel`. Copy
  it; do not edit `AGENTS.md` here (`doc-trim-agents-md-to-the-project`
  does that after this lands).
- `aih role <name>` cats `$AI_HARNESS_HOME/roles/<name>.md`; unknown name
  is exit 2 listing the three.
- Boot prompt in `verbs/dispatch.sh`: "Read AGENTS.md in full; if it has a
  section headed `## ai-harness`, those instructions extend your role. Then
  run `aih role protocol` and `aih role worker` and follow them." Same
  shape for the reviewer.
- Adapters: each says `aih role <role>` instead of a path.
- `doctor`: remove the block check (`verbs/doctor.sh` around line 103).

## Done when
- [ ] `aih role protocol`, `aih role worker`, `aih role reviewer` each print the file; `aih role x` exits 2 and lists the three
- [ ] `aih dispatch worker` with `AI_HARNESS_AGENT_CMD` unset prints a prompt naming `aih role` and the `## ai-harness` section, and no path under `roles/`
- [ ] `grep -rn 'roles/' adapters` prints nothing
- [ ] `aih doctor` passes on a repo whose `AGENTS.md` has no ai-harness block
- [ ] `aih gate` passes
