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

## 4. Publish the release

```sh
gh release create vX.Y.Z ai-harness-X.Y.Z.tar.gz \
  --title vX.Y.Z --notes '<what changed>'
```

## 5. Record the checksum

```sh
shasum -a 256 ai-harness-X.Y.Z.tar.gz
```

Update the formula in `dannycastillo/homebrew-tap` with this sha256 and the
release's tarball URL, so the tap installs this tag.
