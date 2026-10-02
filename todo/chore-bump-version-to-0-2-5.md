# chore: bump VERSION to 0.2.5

- **Priority:** high
- **Touches:** VERSION
- **Blocked by:** —

## Goal
`VERSION` reads `0.2.5`, so trunk `aih-20261002-status-updates` can be
promoted and tagged `v0.2.5`.

## Why
The trunk carries one `feat`: a bare `aih run` detaches by default and
`--foreground` keeps it attached. New observable behavior, but `--detach`
still works, so a patch bump matches the previous releases. RELEASING.md
step 1.

## Notes
- The only change is the one line in `VERSION`. Commit it as
  `chore: bump VERSION to 0.2.5`.
- `.github/workflows/release.yml` fails the release if `VERSION` and the
  tag disagree, so the file must hold exactly `0.2.5` and a newline.

## Done when
- [ ] `cat VERSION` prints `0.2.5`
- [ ] `aih gate` passes
