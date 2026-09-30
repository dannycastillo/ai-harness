# doc: the README defers to aih help and aih protocol

- **Priority:** medium
- **Touches:** README.md
- **Blocked by:** feat-every-verb-answers-help, feat-protocol-is-its-own-verb

## Goal
README.md documents installing and the first run, and for everything
after that points at `aih help`, `aih <verb> --help` and `aih protocol`
instead of carrying its own copy.

## Why
The "Verbs, by owner" table is the third copy of what each verb does,
after `aih help` and now each verb's header, and the copy an installed
agent never sees. The README is read on GitHub before installing; it
should say how to start and where the tool documents itself.

## Notes
- **Verbs, by owner** (from line 159 on 2026-09-29) goes. In its place,
  one short paragraph: `aih help` lists the verbs of the installed copy,
  `aih <verb> --help` says what one reads, writes and refuses and where it
  runs, `aih protocol` is the shared rules. The exit-codes line is in
  `aih help`; drop it here.
- **The two roles** stays: it is about roles, not verbs.
- **Status**: "Every verb in the tables below is built, and all three
  role docs exist: `aih role protocol`, `worker`, `reviewer`" becomes a
  line about `aih role worker|reviewer` and `aih protocol`.
- **Setup**, line 107: `aih version` and `aih help` work anywhere; add
  `aih protocol` and `aih <verb> --help`.
- **Running N workers**, **Stop conditions**, **Configuration**, **State**
  stay. They describe the system, and the README is still the long-form
  read for a human. Trim only what `run --help` now says word for word.
- Quickstart already names `todo/README.md` for the shape; leave it.

## Done when
- [ ] README.md has no "Verbs, by owner" table
- [ ] README.md names `aih help`, `aih <verb> --help` and `aih protocol` as where verbs and rules are documented
- [ ] `grep -n 'role protocol\|tables below' README.md` finds nothing
- [ ] `aih gate` passes
