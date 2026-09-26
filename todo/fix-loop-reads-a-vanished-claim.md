# fix: stop the loop reading a claim a merge just removed

- **Priority:** low
- **Branch:** fix/loop-reads-a-vanished-claim
- **Touches:** ai-harness/lib/run.sh, ai-harness/lib/state.sh
- **Blocked by:** —

## Goal
`run.log` carries no `sed: ... No such file or directory` line when a merge removes a claim mid-tick.

## Why
On the first unattended run (2026-09-26) the loop logged
`sed: .../ai-harness/claims/chore-drop-the-go-skip-check: No such file or directory`
right after that todo merged. Harmless, but a stray error in the loop's log
makes every later real error harder to trust.

## Notes
- The loop lists claims, then reads each one with `ai_harness_kv_get`
  (a `sed` over the file). `integrate --continue` deletes the claim in
  between. Candidates: `ai_harness_run_state` in `lib/run.sh` and
  `ai_harness_claim_count` / `ai_harness_claim_stems` in `lib/state.sh`.
- Fix the reader, not the writer: a claim can vanish at any point, and the
  loop's own docs say it holds no state.
- Reproduce with `aih run --once` while an `integrate --continue --verdict
  pass` finishes in another shell, or by deleting a claim file by hand mid-tick.

## Done when
- [ ] a claim removed between listing and reading is skipped silently
- [ ] `grep 'No such file' .git/ai-harness/log/run.log` prints nothing after a run that merged at least one todo
- [ ] `aih gate` passes
