# doc: add a security policy

- **Priority:** low
- **Touches:** NEW SECURITY.md, .gitattributes
- **Blocked by:** —

## Goal
A stranger who finds a vulnerability in the harness knows how to report it
privately, and knows what the harness does by design that is not a
vulnerability.

## Why
The repo is public and installable, and its commits now carry a noreply
address nobody can write to. GitHub shows a "Security" tab that points at
`SECURITY.md` when one exists; without it the only route is a public issue.
The harness also does things a scanner would flag: it sources
`.ai-harness.conf` as shell and starts agents with the user's own
permissions. Saying so up front separates real reports from those.

## Notes
- Root file, uppercase, like `README.md` and `RELEASING.md`. Short: one
  screen, same tone as AGENTS.md.
- Sections: **Reporting**, **Supported versions**, **What is by design**.
- Reporting: GitHub's private vulnerability reporting on this repo
  (Security tab, "Report a vulnerability"). It works only once a human
  turns it on under Settings, Code security; say so in a `human:` box, not
  in the file. Give danny.webgraphics@gmail.com as the fallback, the
  address already on every commit in this repo's history.
- Supported versions: the latest tagged release only. There are no
  backports.
- By design, so not a report: `.ai-harness.conf` is sourced as POSIX sh by
  every verb; `AI_HARNESS_AGENT_CMD` runs whatever it names, unattended,
  with the invoking user's permissions, inside a worktree the harness
  cut; `run` and `dispatch` put the running copy's `bin` first on an
  agent's PATH. README.md's Quickstart already says the first two; link
  to it rather than restate at length.
- Add `SECURITY.md export-ignore` to `.gitattributes`: it is repo policy,
  not part of the installed tree, like `RELEASING.md`.
- No `CODE_OF_CONDUCT.md`, no `CONTRIBUTING.md`; out of scope here.

## Done when
- [ ] `SECURITY.md` exists at the root with the three sections and fits one screen
- [ ] `git archive --format=tar HEAD | tar -t` does not list `SECURITY.md`
- [ ] human: private vulnerability reporting is enabled in the repo's settings, and the Security tab shows the policy after promotion to `main`
- [ ] `aih gate` passes
