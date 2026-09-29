# plan — what the next run would dispatch, and why the rest waits
#
#   aih plan [<todo-stem>...]
#
# Stems given are the set aih run <stem>... would work, so this is its
# preview. While a loop holds the run lock a bare plan covers only the todos
# outside its set, since those are what the next run could take; claims are
# then left to aih status. Rendering only: the schedule is ai_harness_plan,
# which run, claim and status read directly, and nothing here changes it.

_stems=
for _a in "$@"; do
	case $_a in -*) die "$EX_USAGE" "usage: aih plan [<todo-stem>...]" ;; esac
	_s=${_a#todo/}
	_s=${_s%.md}
	[ -f "$(ai_harness_todo_file "$_s")" ] || die "$EX_USAGE" "plan: no such todo: $_s"
	_stems="$_stems $_s"
done

ai_harness_render_init
# shellcheck disable=SC2154  # _st_tab is set by ai_harness_render_init
_tab=$_st_tab

_names='every todo'
[ -z "$_stems" ] || _names=${_stems# }
_scope='set'
if _run_pid=$(ai_harness_run_live_pid); then
	_set=$(ai_harness_run_set)
	if [ -n "$_set" ]; then
		_run_total=$(printf '%s\n' "$_set" | grep -c .)
	else
		_run_total=$(ai_harness_render_todo_stems | awk 'NF && !seen[$0]++' | grep -c .)
	fi
	printf 'run      %s (Total: %s) is in progress, pid %s; aih status shows it\n' "$(ai_harness_run_set_names)" "$_run_total" "$_run_pid"
	if [ -z "$_stems" ]; then
		[ -n "$_set" ] || { printf 'plan     nothing is outside this run\n' && exit "$EX_OK"; }
		for _s in $(ai_harness_render_outside "$_set"); do
			[ -f "$(ai_harness_todo_file "$_s")" ] && _stems="$_stems $_s"
		done
		[ -n "$_stems" ] || { printf 'plan     nothing is outside this run\n' && exit "$EX_OK"; }
		_names='outside this run'
		_scope=outside
	fi
elif _run_pid=$(ai_harness_run_holder_pid) && [ -n "$_run_pid" ]; then
	printf 'run      lock held by pid %s, which is dead; aih unlock run --force before a new run\n' "$_run_pid"
fi

# shellcheck disable=SC2086  # a list of stems
_out=$(ai_harness_plan $_stems)

_pri_of() {
	_f=$(ai_harness_todo_file "$1")
	_p=
	[ ! -f "$_f" ] || _p=$(ai_harness_todo_field "$_f" Priority)
	printf '%s\n' "${_p:--}"
}

_runs='' _holds='' _claims=''
_nr=0 _nh=0 _nc=0
while IFS="$_tab" read -r _kind _s _third _fourth; do
	[ -n "$_kind" ] || continue
	case $_kind in
	run)
		_nr=$((_nr + 1))
		_runs="$_runs $_tab$_s$_tab""runnable$_tab$_third$_tab""Touches $(ai_harness_todo_field "$(ai_harness_todo_file "$_s")" Touches)
"
		;;
	hold)
		_nh=$((_nh + 1))
		_holds="$_holds $_tab$_s$_tab""held$_tab$(_pri_of "$_s")$_tab$_third
"
		;;
	claimed)
		[ "$_scope" = set ] || continue
		_nc=$((_nc + 1))
		# The row's flag, state and detail; its since column gives way to PRI.
		{ IFS= read -r _flag; IFS= read -r _state; IFS= read -r _detail; } <<EOF2
$(ai_harness_render_row "$_s" "$_out" 0 | awk -F'\t' '{ print $3; print $5; print $7 }')
EOF2
		_claims="$_claims$_flag$_tab$_s$_tab$_state$_tab$(_pri_of "$_s")$_tab""Touches $(ai_harness_kv_get "$(ai_harness_claim_file "$_s")" touches); $_detail
"
		;;
	esac
done <<EOF3
$_out
EOF3

_total=$((_nr + _nh + _nc))
if [ "$_scope" = outside ]; then
	printf 'plan     %s (Total: %s): %s runnable, %s held\n' "$_names" "$_total" "$_nr" "$_nh"
else
	printf 'plan     %s (Total: %s): %s runnable, %s held, %s claimed\n' "$_names" "$_total" "$_nr" "$_nh" "$_nc"
	_active=$(ai_harness_claim_count)
	_free=$((AI_HARNESS_MAX_WORKERS - _active))
	[ "$_free" -ge 0 ] || _free=0
	if [ -f "$(ai_harness_state_dir)/PAUSED" ]; then
		printf 'workers  %s of %s active, but nothing dispatches until aih resume\n' "$_active" "$AI_HARNESS_MAX_WORKERS"
		ai_harness_render_paused
	elif [ "$_nr" -eq 0 ]; then
		printf 'workers  %s of %s active, nothing runnable\n' "$_active" "$AI_HARNESS_MAX_WORKERS"
	elif [ "$_free" -eq 0 ]; then
		printf 'workers  %s of %s active, every slot taken; the top runnable dispatches when one clears\n' "$_active" "$AI_HARNESS_MAX_WORKERS"
	else
		_n=$_free
		[ "$_n" -le "$_nr" ] || _n=$_nr
		_verb=dispatch
		[ "$_n" -ne 1 ] || _verb=dispatches
		printf 'workers  %s of %s active, so the top %s runnable %s next\n' "$_active" "$AI_HARNESS_MAX_WORKERS" "$_n" "$_verb"
	fi
fi

_inbox=$(ai_harness_todo_inbox_summary)
[ -z "$_inbox" ] || printf 'inbox    %s; moved into todo/ to be planned\n' "$_inbox"

if [ "$_total" -eq 0 ]; then
	printf 'nothing in todo/. aih role protocol says how to file one.\n'
	exit "$EX_OK"
fi
printf '\n'
printf '%s%s%s' "$_runs" "$_holds" "$_claims" | ai_harness_render_table PRI

# shellcheck disable=SC2086  # a list of stems
_pairs=$(ai_harness_plan_overlaps $_stems)
[ -z "$_pairs" ] || printf '\noverlaps\n%s\n' "$_pairs"
