# chore: bump VERSION to 0.2.4

- **Priority:** high
- **Touches:** VERSION
- **Blocked by:** —

## Goal
`VERSION` reads `0.2.4`, so trunk `aih-20261001-logging-and-devex` can be
promoted and tagged `v0.2.4`.

## Why
The trunk ships five devex changes: one-line no-trunk error, init on an
empty repo, status from any checkout, padded reports, plan holding an
uncommitted todo. Patch bump as the last three were. RELEASING.md step 1.

## Notes
- The only change is the one line in `VERSION`. Commit it as
  `chore: bump VERSION to 0.2.4`.
- `.github/workflows/release.yml` fails the release if `VERSION` and the
  tag disagree, so the file must hold exactly `0.2.4` and a newline.

## Done when
- [ ] `cat VERSION` prints `0.2.4`
- [ ] `aih gate` passes
