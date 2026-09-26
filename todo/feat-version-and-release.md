# feat: a VERSION file, aih version, and the release steps

- **Priority:** high
- **Branch:** feat/version-and-release
- **Touches:** NEW VERSION, NEW verbs/version.sh, verbs/doctor.sh, README.md, NEW docs/releasing.md
- **Blocked by:** chore-move-the-tree-to-the-repo-root.md

## Goal
The tree knows its version, `doctor` can refuse an old one, and a human can cut a release by following one page.

## Why
adr-2026-09-26-one-install-per-machine: the tap and `install.sh` consume a
tagged tarball. Nothing is taggable without a version.

## Notes
- `VERSION` holds `0.1.0` and nothing else. `aih version` prints it.
- `AI_HARNESS_MIN_VERSION` in a config: `doctor` fails with one line when
  `VERSION` is lower. Compare three dotted integers; no other format.
- `docs/releasing.md`: bump `VERSION` on a branch through the harness, tag
  `vX.Y.Z` on the promoted `main`, `git archive` the tag to
  `ai-harness-X.Y.Z.tar.gz`, `gh release create` with it, record the
  sha256 for the formula. All by a human; the doc is the checklist.
- The first tag is a human's step after this merges and the repo is
  public; not this todo's box.

## Done when
- [ ] `aih version` prints the contents of `VERSION`
- [ ] with `AI_HARNESS_MIN_VERSION` above `VERSION` in a scratch config, `aih doctor` fails and names both numbers
- [ ] with it at or below, or unset, `doctor` is unchanged
- [ ] `docs/releasing.md` exists and a reader can cut a release from it without asking a question
- [ ] `aih gate` passes
