# Releasing

A human's checklist. There is no `aih release` — every step below is a plain
git or `gh` command, run by hand, in order.

See adr-2026-09-26-one-install-per-machine for why a release is a tagged
tarball rather than a package.

## First release

Once, before the first tag: create the tap. `brew tap-new` scaffolds a local
tap with a `Formula/` directory, a README and CI; that checkout becomes the
`dannycastillo/homebrew-tap` repo.

```sh
brew tap-new dannycastillo/tap
cd "$(brew --repository)/Library/Taps/dannycastillo/homebrew-tap"
gh repo create dannycastillo/homebrew-tap --public --source . --push
```

`brew install dannycastillo/tap/ai-harness` works only once
`dannycastillo/ai-harness` is public: the formula downloads from its Releases,
and `brew audit` reports the homepage as a 404 until then.

## Set up once

The `tap` job pushes to `dannycastillo/homebrew-tap` with `TAP_TOKEN`: a
fine-grained personal access token scoped to `homebrew-tap` only, Contents read
and write.

```sh
gh secret set TAP_TOKEN -R dannycastillo/ai-harness
```

When the token expires the `tap` job fails at checkout. Replace the secret and
rerun the job.

## 1. Bump VERSION

Through the harness, like any other change: a `chore` todo, a branch, a
worktree.

```sh
printf '%s\n' 'X.Y.Z' > VERSION
```

Commit as `chore: bump VERSION to X.Y.Z`, then `aih submit` and let
`aih integrate` land it on trunk.

## 2. Promote the trunk

Open the trunk's pull request to `main` once the bump has merged on the trunk,
so the PR carries the version. Merge it after CI is green.

## 3. Tag the promoted commit

Only once that commit is on the promoted `main` — never a worktree branch,
and never before the merge lands.

```sh
git checkout main
git pull
git tag vX.Y.Z
git push origin vX.Y.Z
```

## 4. CI publishes the release and updates the tap

Pushing the tag in step 3 runs `.github/workflows/release.yml`, two jobs:

- `release` fails if `VERSION` disagrees with the tag, then attaches
  `ai-harness-X.Y.Z.tar.gz` and `ai-harness-X.Y.Z.tar.gz.sha256` to a new
  release. The tarball omits the paths marked `export-ignore` in
  `.gitattributes`: only what the installed tree runs.
- `tap` runs after `release` and commits `ai-harness X.Y.Z` to
  `dannycastillo/homebrew-tap`, setting the formula's `url` and `sha256` to this
  tag's tarball. The tap's own test-bot then installs it.

The workflow is safe to rerun if GitHub fails midway: `release` uploads over an
existing release, and `tap` does nothing when the formula already names the
version.

## 5. Verify

```sh
brew update && brew upgrade ai-harness && aih version
```

It prints `X.Y.Z`. The release is done when it does.
