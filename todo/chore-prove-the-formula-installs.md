# chore: prove the formula installs

- **Priority:** high
- **Touches:** packaging/ai-harness.rb, RELEASING.md
- **Blocked by:** fix-version-and-help-run-outside-a-repo

## Goal
`packaging/ai-harness.rb` installs, passes `brew test` and `brew audit
--strict` from a local tarball, and RELEASING.md says how the tap repo is
created the first time.

## Why
The formula has never been installed. README already tells people to
`brew install dannycastillo/tap/ai-harness`; the tap does not exist yet and
the formula's `sha256` is all zeros. Finding what Homebrew rejects before the
first tag means the first release works the first time.

## Notes
- `brew tap-new dannycastillo/tap` scaffolds a local tap at
  `$(brew --repository)/Library/Taps/dannycastillo/homebrew-tap` with a
  `Formula/` directory, a README and a CI workflow. That checkout is the
  future `dannycastillo/homebrew-tap` repo; creating it on GitHub and
  pushing is a human's step, not this todo's.
- Build a tarball the way a release does: `git archive --format=tar.gz
  --prefix=ai-harness-0.1.0/ HEAD -o <tmp>/ai-harness-0.1.0.tar.gz`, then
  `shasum -a 256` it. Copy the formula into the tap's `Formula/` with `url
  "file://<that tarball>"` and that sha256. That copy is throwaway: the
  formula in `packaging/` keeps its GitHub `url`.
- Then, in order: `brew install --build-from-source dannycastillo/tap/ai-harness`,
  `brew test dannycastillo/tap/ai-harness`,
  `brew audit --strict --new dannycastillo/tap/ai-harness`. Fix whatever the
  audit flags in `packaging/ai-harness.rb` and re-copy until all three pass.
- With fix-version-and-help-run-outside-a-repo merged, `aih version` runs
  anywhere, so the `test do` block drops the fake `git init` and the fake
  config and becomes one line:
  `assert_match version.to_s, shell_output("#{bin}/aih version")`.
- Finish with `brew uninstall ai-harness`. Leave the tap in place.
- RELEASING.md gets a short "First release" section before step 1: create
  the tap with `brew tap-new`, `gh repo create dannycastillo/homebrew-tap
  --public`, push; and a line saying `brew install` from the tap works only
  once `dannycastillo/ai-harness` is public, since the formula downloads
  from its Releases. Step 6 stays the per-release update.

## Done when
- [ ] `brew install --build-from-source dannycastillo/tap/ai-harness` succeeds from the `file://` tarball
- [ ] `brew test dannycastillo/tap/ai-harness` passes
- [ ] `brew audit --strict --new dannycastillo/tap/ai-harness` reports nothing
- [ ] the `test do` block in `packaging/ai-harness.rb` creates no git repo and no config
- [ ] `packaging/ai-harness.rb` still points its `url` at GitHub Releases
- [ ] RELEASING.md has the first-release tap steps and the public-repo note
- [ ] `brew uninstall ai-harness` has been run
- [ ] `aih gate` passes
