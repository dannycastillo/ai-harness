# fix: correct three hints that mislead

- **Priority:** low
- **Branch:** fix/misleading-hints
- **Touches:** ai-harness/verbs/help.sh, ai-harness/lib/lock.sh, ai-harness/lib/run.sh
- **Blocked by:** —

## Goal
What `aih` tells a human to do works as written, and a loop's parks reach its log.

## Why
Each one sends a human the wrong way, or hides why the loop stopped.

## Notes
- `verbs/help.sh` lists the exit codes without `4` (the gate cannot run on
  this machine). `ai-harness/README.md` has it.
- `lib/lock.sh`, `ai_harness_lock_wait`, suggests `aih unlock <name>`, which
  refuses without `--force`. `verbs/status.sh` already says `--force`.
- `lib/run.sh`, `ai_harness_run_judge`, runs `integrate --next >/dev/null 2>&1`.
  A park is printed on stderr, so it never reaches `run.log`. Keep stdout
  quiet (it is the packet), let stderr through.

## Done when
- [ ] `aih help` lists exit code 4
- [ ] the stale-lock warning names a command that works when pasted
- [ ] a park during `aih run --detach` appears in `log/run.log`
- [ ] `aih gate` passes
