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

ai_harness_status_init
# shellcheck disable=SC2154  # _st_tab is set by ai_harness_status_init
_tab=$_st_tab

_names=every\ todo
[ -z "$_stems" ] || _names=${_stems# }
_scope='set'
_run_pid=$(sed -n 's/^pid=//p' "$(ai_harness_lock_path run)/holder" 2>/dev/null || :)
if ai_harness_lock_held run && [ -n "$_run_pid" ] && kill -0 "$_run_pid" 2>/dev/null; then
	_st_set_stems=$(ai_harness_run_set)
	if [ -n "$_st_set_stems" ]; then
		_run_names=$(printf '%s\n' "$_st_set_stems" | tr '\n' ' ')
		_run_total=$(printf '%s\n' "$_st_set_stems" | grep -c .)
	else
		_run_names='every todo '
		_run_total=$(ai_harness_status_todo_stems | awk 'NF && !seen[$0]++' | grep -c .)
	fi
	printf 'run      %s(Total: %s) is in progress, pid %s; aih status shows it\n' "$_run_names" "$_run_total" "$_run_pid"
	if [ -z "$_stems" ]; then
		[ -n "$_st_set_stems" ] || { printf 'plan     nothing is outside this run\n' && exit "$EX_OK"; }
		for _s in $(ai_harness_status_outside); do
			[ -f "$(ai_harness_todo_file "$_s")" ] && _stems="$_stems $_s"
		done
		[ -n "$_stems" ] || { printf 'plan     nothing is outside this run\n' && exit "$EX_OK"; }
		_names='outside this run'
		_scope=outside
	fi
elif ai_harness_lock_held run; then
	printf 'run      lock held by pid %s, which is dead; aih unlock run --force before a new run\n' "${_run_pid:-?}"
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
		# rank, seq, flag, stem, state, since, detail: keep flag, state, detail.
		_row=$(ai_harness_status_row "$_s" "$_out" 0)
		_flag=$(printf '%s\n' "$_row" | cut -f3)
		_state=$(printf '%s\n' "$_row" | cut -f5)
		_detail=$(printf '%s\n' "$_row" | cut -f7)
		_claims="$_claims$_flag$_tab$_s$_tab$_state$_tab$(_pri_of "$_s")$_tab""Touches $(ai_harness_kv_get "$(ai_harness_claim_file "$_s")" touches); $_detail
"
		;;
	esac
done <<EOF2
$_out
EOF2

_total=$((_nr + _nh + _nc))
if [ "$_scope" = outside ]; then
	printf 'plan     %s (Total: %s): %s runnable, %s held\n' "$_names" "$_total" "$_nr" "$_nh"
else
	printf 'plan     %s (Total: %s): %s runnable, %s held, %s claimed\n' "$_names" "$_total" "$_nr" "$_nh" "$_nc"
	_active=$(ai_harness_claim_count)
	_free=$((AI_HARNESS_MAX_WORKERS - _active))
	[ "$_free" -ge 0 ] || _free=0
	_paused="$(ai_harness_state_dir)/PAUSED"
	if [ -f "$_paused" ]; then
		printf 'workers  %s of %s active, but nothing dispatches until aih resume\n' "$_active" "$AI_HARNESS_MAX_WORKERS"
		printf 'paused   "%s"\n' "$(cat "$_paused")"
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

if [ "$_total" -eq 0 ]; then
	printf 'nothing in todo/. aih role protocol says how to file one.\n'
	exit "$EX_OK"
fi
printf '\n'
printf '%s%s%s' "$_runs" "$_holds" "$_claims" | ai_harness_status_table PRI

# Every overlapping pair, not just the ones the plan tripped over: two held
# todos that meet will still collide once whatever holds them clears.
_all=
for _f in todo/*.md; do
	[ -f "$_f" ] || continue
	[ "$(basename -- "$_f")" != README.md ] || continue
	_s=$(basename -- "$_f" .md)
	if [ -n "$_stems" ] && [ ! -f "$(ai_harness_claim_file "$_s")" ]; then
		case " $_stems " in *" $_s "*) ;; *) continue ;; esac
	fi
	_all="$_all$_s$_tab$(ai_harness_touches_norm "$(ai_harness_todo_field "$_f" Touches)")
"
done

_pairs=
_rest=$_all
while IFS="$_tab" read -r _a _ta; do
	[ -n "$_a" ] || continue
	_rest=${_rest#*
}
	if [ "$_ta" = ALL ]; then
		_pairs="$_pairs$(printf '  %-34s %s' "$_a" 'against everything (barrier)')
"
		continue
	fi
	while IFS="$_tab" read -r _b _tb; do
		[ -n "$_b" ] && [ "$_tb" != ALL ] || continue
		_w=$(ai_harness_touches_meet "$_ta" "$_tb") || continue
		_pairs="$_pairs$(printf '  %-34s %s  on %s' "$_a" "$_b" "$_w")
"
	done <<EOF3
$_rest
EOF3
done <<EOF4
$_all
EOF4
[ -z "$_pairs" ] || printf '\noverlaps\n%s' "$_pairs"
