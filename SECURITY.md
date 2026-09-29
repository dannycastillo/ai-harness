# Security policy

## Reporting

Report a vulnerability privately, not in a public issue.

- On GitHub: the Security tab, then "Report a vulnerability".
- Otherwise: danny.webgraphics@gmail.com.

Include the version (`aih version`), what you did, and what happened.

## Supported versions

The latest tagged release only. There are no backports.

## What is by design

Not vulnerabilities:

- `.ai-harness.conf` is sourced as POSIX sh by every verb.
- `AI_HARNESS_AGENT_CMD` runs whatever it names, unattended, with the
  invoking user's permissions, inside a worktree the harness cut.
- `run` and `dispatch` put the running copy's `bin` first on an agent's `PATH`.

The first two are spelled out in the [Quickstart](README.md#quickstart).
