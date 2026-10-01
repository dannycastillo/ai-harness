# chore: bump VERSION to 0.2.2

- **Priority:** high
- **Touches:** VERSION
- **Blocked by:** —

## Goal
`VERSION` reads `0.2.2`, so trunk `aih-20261001-bare-run` can be promoted
and tagged `v0.2.2`.

## Why
The trunk carries two `fix` changes: a bare `aih run` with nothing
remembered now records its set so `aih status` reports it, and
`aih abandon` names git's real reason when it keeps a branch. Fixes only,
so a patch bump. RELEASING.md step 1.

## Notes
- The only change is the one line in `VERSION`. Commit it as
  `chore: bump VERSION to 0.2.2`.
- `.github/workflows/release.yml` fails the release if `VERSION` and the
  tag disagree, so the file must hold exactly `0.2.2` and a newline.

## Done when
- [ ] `cat VERSION` prints `0.2.2`
- [ ] `aih gate` passes
