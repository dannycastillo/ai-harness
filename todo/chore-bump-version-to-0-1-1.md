# chore: bump VERSION to 0.1.1

- **Priority:** high
- **Touches:** VERSION
- **Blocked by:** —

## Goal
`VERSION` reads `0.1.1`, so the `v0.1.1` tag on the promoted `main` passes
the release workflow's version check.

## Why
RELEASING.md step 1: the bump goes through the harness like any change,
and `.github/workflows/release.yml` fails when `VERSION` disagrees with
the tag. This trunk is being promoted as PR #47 and is the release.

## Notes
- `printf '%s\n' '0.1.1' > VERSION`. Nothing else changes; the formula in
  `packaging/ai-harness.rb` is updated in the tap repo at release time,
  not here.
- Commit subject exactly `chore: bump VERSION to 0.1.1`.

## Done when
- [ ] `cat VERSION` prints `0.1.1` and `aih version` prints `0.1.1`
- [ ] the diff touches only `VERSION` and removes this todo
- [ ] `aih gate` passes
