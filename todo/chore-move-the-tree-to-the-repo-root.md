# chore: move the tree to the repo root

- **Priority:** high
- **Branch:** chore/move-the-tree-to-the-repo-root
- **Touches:** ALL
- **Blocked by:** —

## Goal
`bin/`, `lib/`, `verbs/`, `roles/`, `adapters/` and the harness README sit at the repo root, and nothing under `ai-harness/` remains.

## Why
adr-2026-09-26-one-install-per-machine: the repo root is the tree, so a
release tarball is the repo and a formula installs it as is. The
`ai-harness/ai-harness/` path only exists because the tool was built inside
another project.

## Notes
- `git mv` so history follows. `ai-harness/README.md` becomes the root
  `README.md`'s body; merge the two, do not keep both.
- Every path that names `ai-harness/`: `.ai-harness.conf` gate globs,
  `.github/workflows/ci.yml`, `lib/selftest.sh:18`, `verbs/doctor.sh:127`,
  `bin/aih:24` (leave the guard in; `chore-drop-the-layout-guard` removes
  it, so for now it compares against `$AI_HARNESS_REPO`), the adapters'
  text, `AGENTS.md` lines 98-99, and this repo's own `.ai-harness.conf`
  `AI_HARNESS_PROTECTED` if it names the old path.
- `.ai-harness.conf`, `.github/workflows/*` and `AGENTS.md` are protected,
  so this parks for a human. Expected: it is `ALL` and runs alone anyway.
- Behaviour is identical after the move. The reviewer checks that and
  nothing else.

## Done when
- [ ] `ls ai-harness` fails: the directory is gone
- [ ] `./bin/aih doctor --selftest` passes from the repo root
- [ ] `./bin/aih check --selftest` passes
- [ ] `grep -rn 'ai-harness/' bin lib verbs roles adapters AGENTS.md README.md .ai-harness.conf .github` prints only lines about the state dir or the config name
- [ ] `git log --follow bin/aih` reaches commits from before the move
- [ ] `aih gate` passes
