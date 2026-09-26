# feat: aih init

- **Priority:** medium
- **Branch:** feat/aih-init
- **Touches:** NEW verbs/init.sh, NEW templates/*, README.md, lib/todo.sh, lib/graph.sh, verbs/plan.sh, verbs/status.sh, lib/gate.sh, verbs/gate.sh, verbs/doctor.sh
- **Blocked by:** feat-aih-role.md, chore-drop-the-layout-guard.md

## Goal
`aih init` in a repo that has never seen the harness writes a confirmed `.ai-harness.conf`, creates `todo/` with a template, copies the adapters whose dot directory exists, and leaves nothing else.

## Why
Step two of the vision: configure trunk, gates, and where todos live, then
run. Replaces `chore-add-the-install-script`, whose first cut is at
`7dbec91` on the local branch `chore/add-the-install-script`; salvage its
stack detection and config template, drop everything that copied the tree
or edited `AGENTS.md`.

## Notes
- Detection, in order: `go.mod`; `package.json` scripts that exist;
  `Cargo.toml`; `pyproject.toml` tools actually declared; `Makefile`
  targets. Unrecognised means an empty gate, which is allowed: `doctor`
  reports "no gates declared" as a row, not a failure.
- Always print the generated config and require `--yes` or an interactive
  confirm. Never guess a gate silently.
- Trunk defaults to the current branch. Ask, or take `--trunk`.
- `templates/todo-README.md` goes to `todo/README.md`: the shape, one
  example, and "run `aih role protocol` for the rules". `plan` must ignore
  `README.md` in `todo/`.
- Adapters copy only into a dot directory that already exists; never
  create one.
- Refuses to overwrite an existing `.ai-harness.conf` without `--force`.

## Done when
- [ ] in a scratch Go repo, `aih init --yes` writes a config whose gates run, creates `todo/README.md`, and `aih doctor` passes
- [ ] in a scratch repo with no recognisable stack, it writes an empty gate and `doctor` passes with a "no gates" row
- [ ] it prints the config and stops without `--yes` or a confirm
- [ ] with `.claude/` present it copies the claude-code adapter; with none present it creates no dot directory
- [ ] `aih plan` ignores `todo/README.md`
- [ ] `aih gate` passes
