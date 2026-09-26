# ai-harness

`aih` runs several AI coding agents on one repo at once: one todo, one branch,
one worktree each, with trunk written only by a single `integrate` verb.

It is POSIX sh and knows nothing about your project's language. Everything
project-specific lives in `.ai-harness.conf`.

- How it works, the verbs, and configuration: [`ai-harness/README.md`](ai-harness/README.md)
- The two roles: [`ai-harness/roles/`](ai-harness/roles/)
- Working agreements for this repo: [`AGENTS.md`](AGENTS.md)
- Decisions: [`docs/`](docs/)

This repo was split out of
[`dannycastillo/wut-command`](https://github.com/dannycastillo/wut-command),
another project of the author's, where the harness was originally built.

There is no packaged install yet. A Homebrew tap and an `install.sh` are
coming; until then, clone this repo to use `aih`.
