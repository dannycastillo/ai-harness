# chore: bump VERSION to 0.2.3

- **Priority:** high
- **Touches:** VERSION
- **Blocked by:** —

## Goal
`VERSION` reads `0.2.3`, so trunk `aih-20261001-release-flow` can be
promoted and tagged `v0.2.3`.

## Why
The trunk changes the release workflow: a rerun-safe publish step and a
`tap` job that pushes the formula bump to `homebrew-tap`. The tag is the
first end-to-end run of that job. No tool behaviour changes, so a patch
bump. RELEASING.md step 1.

## Notes
- The only change is the one line in `VERSION`. Commit it as
  `chore: bump VERSION to 0.2.3`.
- `.github/workflows/release.yml` fails the release if `VERSION` and the
  tag disagree, so the file must hold exactly `0.2.3` and a newline.

## Done when
- [ ] `cat VERSION` prints `0.2.3`
- [ ] `aih gate` passes
