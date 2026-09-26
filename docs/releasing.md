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

## 3. Archive the tag

```sh
git archive --format=tar.gz --prefix=ai-harness-X.Y.Z/ vX.Y.Z \
  -o ai-harness-X.Y.Z.tar.gz
```

## 4. Checksum the tarball

`install.sh` fetches this file, named after the tarball, to verify what it
downloaded.

```sh
shasum -a 256 ai-harness-X.Y.Z.tar.gz | awk '{print $1}' \
  > ai-harness-X.Y.Z.tar.gz.sha256
```

## 5. Publish the release

Both files, so `install.sh` finds the checksum next to the tarball.

```sh
gh release create vX.Y.Z ai-harness-X.Y.Z.tar.gz ai-harness-X.Y.Z.tar.gz.sha256 \
  --title vX.Y.Z --notes '<what changed>'
```

## 6. Update the tap

`packaging/ai-harness.rb` in this repo is the formula, kept for review; a
release copies it into `dannycastillo/homebrew-tap` as `Formula/ai-harness.rb`,
with its `url` and `sha256` set to this tag's tarball and the checksum from
step 4. Commit and push there — that repo has no `aih` of its own.
