# chore: release on tag from CI

- **Priority:** low
- **Touches:** NEW .github/workflows/release.yml, RELEASING.md
- **Blocked by:** —

## Goal
Pushing a `vX.Y.Z` tag produces the GitHub Release, with the tarball and
its checksum attached, and RELEASING.md shrinks to match.

## Why
RELEASING.md steps 3 to 5 are archive, checksum, `gh release create`, run
by hand. The tap's `sha256` must equal the checksum of the asset actually
uploaded; a workflow that builds and uploads both from the tag makes that
true by construction and cuts a release to `git tag && git push`.

## Notes
- `.github/workflows/release.yml`, `on: push: tags: ['v*']`,
  `permissions: contents: write`. Steps: `actions/checkout@v4`, derive
  `X.Y.Z` from `${GITHUB_REF_NAME#v}`, `git archive --format=tar.gz
  --prefix=ai-harness-X.Y.Z/ "$GITHUB_REF_NAME" -o ai-harness-X.Y.Z.tar.gz`,
  `sha256sum ... | awk '{print $1}' > ai-harness-X.Y.Z.tar.gz.sha256`,
  `gh release create "$GITHUB_REF_NAME" <both files> --title
  "$GITHUB_REF_NAME" --generate-notes` with `GH_TOKEN:
  ${{ github.token }}`.
- Asset names are a contract: `install.sh` fetches
  `ai-harness-<version>.tar.gz` and `ai-harness-<version>.tar.gz.sha256`
  from the release, and the formula's `url` names the tarball. Do not
  rename them.
- Check the tag's `VERSION` file equals `X.Y.Z` and fail the job if not, so
  a tag can't ship a tree that claims another version.
- RELEASING.md: steps 3, 4 and 5 collapse into "push the tag; CI attaches
  the assets". Steps 1, 2 and 6 stay.
- `.github/workflows/*` is in `AI_HARNESS_PROTECTED`, so `aih check`
  reports `protected-path` and `integrate` parks this branch every time.
  That is by design: a human reads the workflow and merges it by hand.
  Submit anyway; the park is the hand-off.
- Nothing here can be exercised from a worktree; the one real test is the
  first tag, which is a human's.

## Done when
- [ ] `.github/workflows/release.yml` exists and `ruby -ryaml -e 'YAML.load_file(ARGV[0])' .github/workflows/release.yml` exits 0
- [ ] the workflow uploads exactly `ai-harness-X.Y.Z.tar.gz` and `ai-harness-X.Y.Z.tar.gz.sha256`, and fails when `VERSION` disagrees with the tag
- [ ] RELEASING.md steps 3 to 5 are replaced by the tag push
- [ ] human: pushing `v0.1.0` produces a release with both assets, and `install.sh` installs from it
- [ ] `aih gate` passes
