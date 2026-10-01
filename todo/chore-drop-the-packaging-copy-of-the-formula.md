# chore: drop the packaging copy of the formula

- **Priority:** medium
- **Touches:** packaging/*, .gitattributes
- **Blocked by:** —

## Goal
This repo holds no copy of the Homebrew formula. `Formula/ai-harness.rb` in
`dannycastillo/homebrew-tap` is the only one.

## Why
`packaging/ai-harness.rb` says "kept for review" but still reads v0.1.0
with an all-zero sha256 three releases later; nothing reads it and nobody
reviews it. Once the release workflow pushes the bump to the tap itself,
a second hand-maintained copy can only lag and mislead.

## Notes
- Delete `packaging/ai-harness.rb`; the directory goes with it.
- Remove the `packaging export-ignore` line from `.gitattributes`. Leave
  every other line.
- RELEASING.md still mentions `packaging/ai-harness.rb` at line 58; that
  file is not in Touches and is rewritten by
  `doc-releasing-ends-at-the-tag.md`. Do not edit it here.

## Done when
- [ ] `packaging/` does not exist
- [ ] `.gitattributes` has no `packaging` line and is otherwise unchanged
- [ ] `git grep -n packaging` matches only RELEASING.md
- [ ] `aih gate` passes
