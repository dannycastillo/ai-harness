# fix: role runs anywhere

- **Priority:** medium
- **Touches:** bin/aih, verbs/role.sh, README.md
- **Blocked by:** —

## Goal
`aih role worker` and `aih role reviewer` print from any directory,
repository or not, the way `aih protocol` does.

## Why
`role` reads two files from the installed tree and nothing from the
repository, yet `bin/aih` sends it through the repository and config
checks, so from `/tmp` it dies with `not inside a git repository` while
`aih protocol` prints. A session standing outside a trunk that asks what
a worker does should get the answer.

## Notes
- `bin/aih` line 49: `help | version | protocol) ;;` gains `role`. That
  case skips `AI_HARNESS_REPO`, the config and the trunk guard, which is
  what `role` needs: it never reads them.
- `verbs/role.sh` header, the `Runs:` line: "anywhere, inside a repository
  or not", matching `protocol.sh`.
- README.md line 107 lists the verbs that work anywhere; add `aih role`.
- `roles/protocol.md`'s where-verbs-run paragraph names no verbs and needs
  no change.

## Done when
- [ ] from a directory that is not a git repository, `./bin/aih role worker` and `./bin/aih role reviewer` exit 0 and print the protocol followed by the role
- [ ] `./bin/aih role --help` says it runs anywhere
- [ ] README.md's list of verbs that work anywhere includes `aih role`
- [ ] `aih gate` passes
