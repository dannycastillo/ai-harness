# chore: trim the release tarball

- **Priority:** medium
- **Touches:** NEW .gitattributes, RELEASING.md
- **Blocked by:** —

## Goal
`git archive` of a tag ships only what the installed tree runs.

## Why
A release is `git archive` of a tag (adr-2026-09-26-one-install-per-machine),
and the formula puts the whole archive under `libexec`. Today that carries
this repo's own `.ai-harness.conf`, `AGENTS.md`, `todo/`, `test/`, `docs/`,
`.github/`, `packaging/` and `install.sh` onto every machine that installs
it. None of it runs; the config and `AGENTS.md` in particular describe this
repo, not the one the harness is installed for.

## Notes
- Add `.gitattributes` at the root with an `export-ignore` line per path:
  `.github`, `.gitattributes`, `.gitignore`, `.ai-harness.conf`, `AGENTS.md`,
  `RELEASING.md`, `docs`, `packaging`, `test`, `todo`, `install.sh`.
- Keep everything the tree reads at runtime: `bin/`, `lib/`, `verbs/`,
  `roles/` (`aih role`, adr-2026-09-26-the-protocol-ships-with-the-tree),
  `adapters/` and `templates/` (`aih init` copies from both), `VERSION`,
  `LICENSE`, `README.md`. `grep -rn 'AI_HARNESS_HOME"/' bin lib verbs` lists
  the directories the tree reaches into.
- Verify the trimmed archive through `install.sh`'s local path:
  `AI_HARNESS_TARBALL=<archive>` skips the download. Point `HOME` at a
  throwaway directory for that run, never the real one, so nothing under
  `~/.local` changes.
- RELEASING.md, step 3: one line saying the archive omits the paths in
  `.gitattributes`.

## Done when
- [ ] `git archive --format=tar HEAD | tar -t` lists none of `.github/`, `.ai-harness.conf`, `AGENTS.md`, `RELEASING.md`, `docs/`, `packaging/`, `test/`, `todo/`, `install.sh`
- [ ] the same listing still has `bin/aih`, `roles/protocol.md`, `templates/ai-harness.conf`, `adapters/`, `VERSION`
- [ ] `HOME=$(mktemp -d) AI_HARNESS_TARBALL=<that archive, gzipped> sh install.sh` installs, and `$HOME/.local/bin/aih version` from a git repo prints the tree's `VERSION`
- [ ] RELEASING.md step 3 names what the archive omits
- [ ] `aih gate` passes
