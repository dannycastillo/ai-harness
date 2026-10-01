# chore: bump VERSION to 0.2.0

- **Priority:** high
- **Touches:** VERSION
- **Blocked by:** —

## Goal
`VERSION` reads `0.2.0`, so trunk `ai-harness-20260930` can be promoted and
tagged `v0.2.0`.

## Why
The trunk carries a `feat` change to `aih init` (three-option trunk menu,
push prompt, no config printout, Sonnet agent command in the template)
plus the README quickstart and the first-run gate. New user-visible
behaviour takes a minor bump under 0.x. RELEASING.md step 1.

## Notes
- The only change is the one line in `VERSION`. Commit it as
  `chore: bump VERSION to 0.2.0`.
- `.github/workflows/release.yml` fails the release if `VERSION` and the
  tag disagree, so the file must hold exactly `0.2.0` and a newline.

## Done when
- [ ] `cat VERSION` prints `0.2.0`
- [ ] `aih gate` passes
