# chore: the release workflow pushes the formula bump to the tap

- **Priority:** high
- **Touches:** .github/workflows/release.yml
- **Blocked by:** —

## Goal
Pushing a `vX.Y.Z` tag ends with `Formula/ai-harness.rb` in
`dannycastillo/homebrew-tap` naming that tag's tarball and its sha256,
committed there as `ai-harness X.Y.Z`, with no human step in between.

## Why
RELEASING.md step 4 has a human copy a 64-character hash into the tap by
hand, and the repo's `packaging/` copy of the formula has not been updated
since v0.1.0 because nobody looks at it. The tap's own CI already installs
the formula on every push to its `main`, so a push from the release is
verified without a pull request. Also seen on 2026-10-01: the v0.2.2 release
run died on an HTTP 500 inside `gh release create`; the rerun only worked
because nothing had been created yet.

## Notes
- `.github/workflows/release.yml` has one job, `release`, lines 12 to 31.
  Keep the VERSION check and `git archive` as they are.
- Make the publish step safe to rerun: when `gh release view
  "$GITHUB_REF_NAME"` succeeds, `gh release upload "$GITHUB_REF_NAME"
  "$tarball" "$tarball.sha256" --clobber`; otherwise create as today.
- Give that step an `id:` and write `version=$version` and
  `sha256=$(cat "$tarball.sha256")` to `$GITHUB_OUTPUT`. Declare both as
  `outputs:` on the `release` job.
- Add a second job, `tap`, with `needs: release`, on `ubuntu-latest`:
  - `actions/checkout@v7` with `repository: dannycastillo/homebrew-tap`
    and `token: ${{ secrets.TAP_TOKEN }}`.
  - One `run:` step under `set -eu`. Read `v` and `sha` from
    `needs.release.outputs`. `f=Formula/ai-harness.rb`. If `grep -q
    "ai-harness-$v.tar.gz" "$f"` already matches, print one line and exit 0:
    a rerun must not commit twice.
  - Rewrite the two lines with sed:
    `s|releases/download/v[^/]*/ai-harness-[^"]*|releases/download/v$v/ai-harness-$v.tar.gz|`
    and `s|^  sha256 ".*"|  sha256 "$sha"|`.
  - `git config user.name github-actions`, `git config user.email
    github-actions@github.com`, `git commit -am "ai-harness $v"`,
    `git push`.
- The job needs no `permissions:` block of its own; the token is the
  secret. Do not pass `TAP_TOKEN` to any other step or job.
- `TAP_TOKEN` is a fine-grained personal access token scoped to
  `homebrew-tap` only, Contents read and write, set by a human with
  `gh secret set TAP_TOKEN -R dannycastillo/ai-harness`. If it is absent the
  `tap` job fails at checkout and the release itself is untouched; that is
  the intended failure.
- Pushes made with a personal token trigger the tap's `brew test-bot`
  workflow on its `main`, so this job does not need to verify the install.
- Actions cannot run here. Check the YAML parses with
  `ruby -ryaml -e 'YAML.load_file(".github/workflows/release.yml")'`, and
  run `shellcheck -s bash` on each `run:` block pasted into a temp file.
- The release notes, the `packaging/` copy and RELEASING.md are other
  todos. Change nothing outside this file.

## Done when
- [ ] `release.yml` has jobs `release` and `tap`, and `tap` has `needs: release`
- [ ] the publish step uploads with `--clobber` when the release already exists, and creates it otherwise
- [ ] the `release` job declares outputs `version` and `sha256`
- [ ] the `tap` job exits 0 without committing when the formula already names the version
- [ ] the YAML parses and shellcheck passes on every `run:` block
- [ ] human: the next tag's run pushes `ai-harness X.Y.Z` to the tap and its test-bot is green
- [ ] `aih gate` passes
