# chore: the harness relies only on the todo's Branch field

- **Priority:** high
- **Branch:** chore/rely-only-on-the-branch-field
- **Touches:** lib/todo.sh, lib/check.sh, lib/graph.sh, verbs/claim.sh, verbs/submit.sh, verbs/check.sh, verbs/log.sh, verbs/plan.sh, roles/protocol.md, README.md
- **Blocked by:** feat-aih-role.md

## Goal
The harness takes a todo's branch from its **Branch** field and nothing else, enforces a naming convention only when the project declares one, and `roles/protocol.md` states only what the harness enforces.

## Why
Branch naming is a project's convention. Today `claim` derives the branch
from the todo's filename and `AI_HARNESS_PREFIXES`, `todo_validate`
rejects a Branch field that differs from that derivation, and `submit`,
`check` and `log` map a branch back to its todo by swapping `/` for `-`.
A project that names branches differently cannot use the harness at all.
The test for `protocol.md` is: a rule belongs there only if the harness
enforces it mechanically.

## Notes
- `claim`: branch is the Branch field verbatim. `todo_validate`: Branch
  is non-empty and passes `git check-ref-format --branch`; no filename
  rule. The filename is still the stem, and the stem is still the key for
  claims, state and `Touches`.
- Branch to stem: look the branch up in `claims/*` (each records
  `branch=`). `submit` and `check` run on a claimed branch, so a claim
  exists. `log` reads merge trailers, which carry the todo path already;
  where it falls back to a branch name, scan the trunk's `todo/*.md`
  Branch fields.
- `AI_HARNESS_PREFIXES` becomes optional. Set: `check` keeps the
  `bad-subject` stop on commit subjects. Unset: no subject check. Nothing
  else reads it. This repo's config keeps it, so its own convention stays
  enforced.
- `plan` and `graph.sh`: "branch exists unclaimed" uses the Branch field.
- `roles/protocol.md`: drop the Git workflow section (branch for
  everything, four prefixes, one branch unless, naming). In its place, one
  short section: the Branch field is the branch; the harness enforces
  commit-subject prefixes only when `AI_HARNESS_PREFIXES` is set; how a
  project names branches and writes commits is the project's, in its
  `AGENTS.md`. Keep Working in parallel and the Todo section.
- README: the config table's `AI_HARNESS_PREFIXES` row says optional.

## Done when
- [ ] a todo whose Branch field is `work/anything-here` claims onto that branch and submits from it, with `AI_HARNESS_PREFIXES` unset in a scratch config
- [ ] with `AI_HARNESS_PREFIXES` set, a commit subject outside it still parks `bad-subject`; unset, it does not
- [ ] `aih check --selftest` passes
- [ ] `roles/protocol.md` has no branch-naming or commit-prefix convention beyond the two sentences above
- [ ] `aih gate` passes
