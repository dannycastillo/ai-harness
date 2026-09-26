# chore: make the repo public

- **Priority:** high
- **Branch:** chore/make-the-repo-public
- **Touches:** README.md
- **Blocked by:** —

## Goal
`dannycastillo/ai-harness` is public, and its README tells a stranger what it is and that the install is coming.

## Why
The Homebrew tap and `install.sh` both fetch a tagged tarball from GitHub
Releases, which needs a public repo. Every install todo waits on this.

## Notes
- A human flips visibility (`gh repo edit --visibility public`); an agent
  never does. A worker does the scan and the README and submits; the flip
  is the reviewer's last box by hand.
- `gitleaks detect` over the full history first. Anything it finds is a
  human's to judge before the flip.
- The README's one-paragraph pitch stands. Replace the wut-command
  paragraph's tone for someone who has never seen wut: keep the pointer,
  drop the assumption. Do not write the quickstart here; that is
  `doc-quickstart-readme`.

## Done when
- [ ] `gitleaks detect` over the full history reports nothing
- [ ] README reads for someone who has never seen wut-command and says an installable release is coming
- [ ] human: the repo's visibility is public
- [ ] `aih gate` passes
