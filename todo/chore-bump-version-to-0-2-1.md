# chore: bump VERSION to 0.2.1

- **Priority:** high
- **Touches:** VERSION
- **Blocked by:** —

## Goal
`VERSION` reads `0.2.1`, so trunk `aih-20261001-naming-cleanups` can be
promoted and tagged `v0.2.1`.

## Why
The trunk carries one `fix`: `aih gate` warns and passes on an empty gate
list instead of exiting 4. A fix with no new behaviour is a patch bump
under 0.x. RELEASING.md step 1.

## Notes
- The only change is the one line in `VERSION`. Commit it as
  `chore: bump VERSION to 0.2.1`.
- `.github/workflows/release.yml` fails the release if `VERSION` and the
  tag disagree, so the file must hold exactly `0.2.1` and a newline.

## Done when
- [ ] `cat VERSION` prints `0.2.1`
- [ ] `aih gate` passes
