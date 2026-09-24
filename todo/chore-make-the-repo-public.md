# chore: make the repo public

- **Priority:** low
- **Branch:** chore/make-the-repo-public
- **Touches:** README.md, LICENSE
- **Blocked by:** chore-add-ci.md

## Goal
`dannycastillo/ai-harness` is public, and the README is ready for someone who
has never seen wut.

## Why
The repo starts private until it's ready. Once its history is public, it can't
be taken back.

## Notes
- A grep of the history for keys and tokens was clean at the split
  (2026-09-24). Run `gitleaks detect` over the full history once more before
  the switch.
- The commit emails in the history become public too.
- References like `dannycastillo/wut-command#21` only resolve for readers who
  can see wut-command.
- The switch itself: `gh repo edit dannycastillo/ai-harness --visibility public
  --accept-visibility-change-consequences`.

## Done when
- [ ] `gitleaks detect` over the full history reports nothing
- [ ] README says how to add the harness to another repo
- [ ] the repo's visibility is public
