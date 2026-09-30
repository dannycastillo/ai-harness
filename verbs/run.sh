# run — work a set of todos unattended: dispatch, judge, merge, until idle
#
# usage: aih run [<todo-stem>...] [--all] [--detach] [--once]
#
# A shell loop, not an agent. Each tick it reaps exited agents, kills any past
# AI_HARNESS_AGENT_TIMEOUT, dispatches workers up to AI_HARNESS_MAX_WORKERS
# from aih plan, and moves the queue a step: integrate --next, then a reviewer.
# Stems given are remembered; a bare run reuses the last set, and --all takes
# the todos in todo/ now: work filed later waits for the next run. aih plan
# <stem>... previews the same set. --detach starts the loop under nohup and
# prints its pid. --once runs a single tick. Needs AI_HARNESS_AGENT_CMD.
#
# Runs: the trunk checkout only. Exit 0 every todo merged or held with a
# reason, 1 a stop for a human, 3 paused and drained.

_detach=no
_once=no
_all=no
_stems=
while [ $# -gt 0 ]; do
	case $1 in
	--detach) _detach=yes ;;
	--once) _once=yes ;;
	--all) _all=yes ;;
	-*) die "$EX_USAGE" "run: unknown option: $1" ;;
	*)
		_s=${1#todo/}
		_s=${_s%.md}
		ai_harness_todo_validate "$_s" || die "$EX_USAGE" "run: $_s did not validate"
		_stems="$_stems$_s
"
		;;
	esac
	shift
done

_trunk_wt=$(ai_harness_trunk_worktree)
[ "$AI_HARNESS_REPO" = "$_trunk_wt" ] ||
	die "$EX_USAGE" "run: run it from the $AI_HARNESS_TRUNK checkout (${_trunk_wt:-none exists})"
[ -n "${AI_HARNESS_AGENT_CMD:-}" ] || die "$EX_USAGE" "run: AI_HARNESS_AGENT_CMD is unset in .ai-harness.conf"
! ai_harness_lock_held run || die "$EX_FAIL" "run: a loop is already running — $(ai_harness_lock_who run)"

mkdir -p "$(dirname -- "$(ai_harness_run_file set)")"
if [ "$_all" = yes ]; then
	for _f in todo/*.md; do
		[ -f "$_f" ] || continue
		[ "$(basename -- "$_f")" != README.md ] || continue
		basename -- "$_f" .md
	done >"$(ai_harness_run_file set)"
	: >"$(ai_harness_run_file all)"
elif [ -n "$_stems" ]; then
	printf '%s' "$_stems" >"$(ai_harness_run_file set)"
	rm -f "$(ai_harness_run_file all)"
fi

if [ "$_detach" = yes ]; then
	_log="$(ai_harness_state_dir)/log/run.log"
	mkdir -p "$(dirname -- "$_log")"
	_args=
	[ "$_once" = no ] || _args=--once
	# shellcheck disable=SC2086  # _args is a flag or empty
	_pid=$(set -m; nohup "$AI_HARNESS_HOME/bin/aih" run $_args </dev/null >>"$_log" 2>&1 & printf '%s\n' "$!")
	log "run: loop pid $_pid, log $_log"
	printf '%s\n' "$_pid"
	exit "$EX_OK"
fi

ai_harness_lock_acquire run || die "$EX_FAIL" "run: a loop is already running — $(ai_harness_lock_who run)"
trap 'ai_harness_lock_release run' EXIT
_set=$(ai_harness_run_set_names)
ai_harness_event @run - started "$_set"
log "run: working $_set"

rm -f "$(ai_harness_run_file failed)".*
_halt() {
	log "run: $1"
	ai_harness_event @run - stopped "$1"
	_rc=$EX_FAIL
}

_rc=$EX_OK
while :; do
	ai_harness_agents_reap
	ai_harness_run_timeouts
	if _stop=$(ai_harness_run_dispatch); then :; else
		_halt "$_stop"
		break
	fi
	if _stop=$(ai_harness_run_judge); then :; else
		_halt "$_stop"
		break
	fi
	if _lost=$(ai_harness_run_lost); then
		_halt "reviewer-lost $_lost: aih dispatch reviewer --detach, or integrate --continue --park"
		break
	fi
	if ai_harness_run_idle; then
		if _stop=$(ai_harness_run_unfinished); then
			_halt "$_stop"
		elif [ -f "$(ai_harness_state_dir)/PAUSED" ]; then
			ai_harness_event @run - stopped "paused and drained"
			_rc=$EX_PAUSED
		else
			ai_harness_event @run - idle "nothing runnable, nothing in flight"
		fi
		break
	fi
	[ "$_once" = no ] || break
	sleep "${AI_HARNESS_RUN_POLL:-10}"
done
# The loop's final report: the same call `aih status` makes, so the two
# cannot disagree.
ai_harness_render_status >&2
exit "$_rc"
