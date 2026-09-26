# fix: the Go build gate writes a binary into the checkout

- **Priority:** high
- **Touches:** verbs/init.sh

## Goal
`aih init` on a Go repo declares a build gate that leaves the tree clean.

## Why
`go build ./...` writes a binary when the module is a single `main`
package. The baseline gate then dirties the trunk checkout and every
`integrate` parks `dirty-trunk`; the worker's `aih gate` dirties its
worktree and the post-merge cleanup is refused. Seen on the quickstart's
scratch repo on 2026-09-26: the first run of a hello-world module cannot
merge without a human deleting the binary.

## Notes
- `go build -o /dev/null ./...` compiles the same packages and writes
  nothing.
- Check the other detectors for the same fault: a gate must never write
  into the tree it checks.

## Done when
- [ ] `_detect_go` in `verbs/init.sh` declares `go build -o /dev/null ./...`
- [ ] on a scratch module with one `main` package, `./bin/aih init --yes` then `./bin/aih gate --full` leaves `git status --short` empty
- [ ] `aih gate` passes
