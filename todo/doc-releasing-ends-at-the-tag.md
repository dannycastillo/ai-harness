# doc: RELEASING.md ends at the tag

- **Priority:** medium
- **Touches:** RELEASING.md
- **Blocked by:** chore-release-pushes-the-formula-to-the-tap.md, chore-drop-the-packaging-copy-of-the-formula.md

## Goal
RELEASING.md describes the release as it works once the two chores it is
blocked by have landed: a human bumps, promotes and tags; CI publishes the
release and updates the tap; the human verifies with one command.

## Why
The checklist today jumps from "bump VERSION on the trunk" to "tag the
promoted commit" without saying how the trunk reaches `main`, has no
verification step, and ends with a hand edit of the tap that CI now does.
On 2026-10-01 the trunk PR was opened before the bump and had to be
revisited, and the local install was still on the old version afterwards
because nothing said to upgrade it.

## Notes
- Read `.github/workflows/release.yml` as merged and name its jobs, not
  the ones this todo expects.
- Keep "First release" and step 1 as they are.
- Insert a promote step after the bump: open the trunk's pull request to
  `main` once the bump has merged on the trunk, so the PR carries the
  version; merge it after CI; then tag.
- Step "CI publishes the release": add that the `tap` job then commits
  `ai-harness X.Y.Z` to `dannycastillo/homebrew-tap`, whose own test-bot
  installs it. Say the workflow is safe to rerun if GitHub fails mid-way.
- Replace "4. Update the tap" with a verify step:
  `brew update && brew upgrade ai-harness && aih version` prints `X.Y.Z`.
- Add a short "Set up once" note: `TAP_TOKEN` is a fine-grained personal
  access token for `homebrew-tap` only, Contents read and write, stored with
  `gh secret set TAP_TOKEN -R dannycastillo/ai-harness`, and the `tap` job
  fails at checkout when it expires.
- Remove every mention of `packaging/ai-harness.rb`.

## Done when
- [ ] RELEASING.md names the steps in order: bump, promote, tag, CI publishes and updates the tap, verify
- [ ] `grep -n packaging RELEASING.md` matches nothing
- [ ] the job names in RELEASING.md match those in `.github/workflows/release.yml`
- [ ] `aih gate` passes
