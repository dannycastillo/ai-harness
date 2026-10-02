# feat: run detaches by default

- **Priority:** high
- **Touches:** verbs/run.sh roles/protocol.md README.md
- **Blocked by:** —

## Goal
A bare `aih run` starts the loop in the background, prints what it is
working and the three verbs to watch and stop it, and returns the tty.
`--foreground` keeps the loop attached.

## Why
The agents are already detached under `nohup`; the foreground only holds a
loop that sleeps ten seconds between ticks and is silent most of the time.
Ctrl-C on it releases the run lock and leaves every agent running with
nobody reaping or judging them. `aih status`, `aih log` and `aih stop`
are already the way to watch and stop a run. Every real invocation so far
has been `run --all --detach`.

## Notes
- `verbs/run.sh`: replace `_detach=no` with the inverse. Add `--foreground`
  to the option loop; `--once` implies foreground, a single tick that
  detaches is pointless. Accept `--detach` as a no-op this release so
  existing muscle memory and prompts keep working; drop it next release.
- The detach branch today prints `run: loop pid N, log P` and the bare pid.
  Replace with the set being worked (`ai_harness_run_set_names`), then the
  pid and log, then three indented lines:
  `aih status   what it is doing`, `aih log   what it has done`,
  `aih stop   stop the loop and its agents`. Keep the bare pid on stdout
  as the last line, so `pid=$(aih run)` still works.
- Startup errors (no trunk, `AI_HARNESS_AGENT_CMD` unset, lock held) already
  fire before the detach branch; keep them there so a failed start never
  backgrounds.
- The header comment is `--help` (adr-2026-09-29-help-lives-in-the-verb):
  update the usage line and the `--detach` sentence there, not elsewhere.
- `roles/protocol.md:121-122` show `aih run ... --detach`; drop the flag.
  Lines 148-153 are `dispatch --detach` and stay.
- `README.md:73-92` "Starting a Run": one sentence that run returns at once
  and the loop keeps going; `aih stop` ends it. The existing `aih status` /
  `aih log` sentence already covers watching.
- No ADR: a flag default, cheap to reverse; the reasoning is the commit body.
- `lib/render.sh:296` says `aih run --all starts one`, still true; leave it.

## Done when
- [ ] `aih run --all` returns within a second with the loop running, and
      prints the set, pid, log path and the three verbs
- [ ] `aih run --all --foreground` behaves as today's bare run
- [ ] `aih run --once` runs one tick attached, with or without `--foreground`
- [ ] `aih run --all --detach` works and prints no warning
- [ ] `aih run --help` describes `--foreground` and no longer documents
      `--detach` as the way to background
- [ ] `aih gate` passes
