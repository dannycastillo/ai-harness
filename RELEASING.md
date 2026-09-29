# Releasing

A human's checklist. There is no `aih release` — every step below is a plain
git or `gh` command, run by hand, in order.

See adr-2026-09-26-one-install-per-machine for why a release is a tagged
tarball rather than a package.

## 1. Bump VERSION

Through the harness, like any other change: a `chore` todo, a branch, a
worktree.

```sh
printf '%s\n' 'X.Y.Z' > VERSION
```

Commit as `chore: bump VERSION to X.Y.Z`, then `aih submit` and let
`aih integrate` land it on trunk.

## 2. Tag the promoted commit

Only once that commit is on the promoted `main` — never a worktree branch,
and never before the merge lands.

```sh
git checkout main
git pull
git tag vX.Y.Z
git push origin vX.Y.Z
```

## 3. CI publishes the release

Pushing the tag in step 2 runs `.github/workflows/release.yml`. It fails if
`VERSION` disagrees with the tag, then attaches `ai-harness-X.Y.Z.tar.gz` and
`ai-harness-X.Y.Z.tar.gz.sha256` to a new release. The tarball omits the paths
marked `export-ignore` in `.gitattributes`: only what the installed tree runs.

## 4. Update the tap

`packaging/ai-harness.rb` in this repo is the formula, kept for review; a
release copies it into `dannycastillo/homebrew-tap` as `Formula/ai-harness.rb`,
with its `url` and `sha256` set to this tag's tarball and the contents of the
release's `.sha256` asset. Commit and push there — that repo has no `aih` of its own.
