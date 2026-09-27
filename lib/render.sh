# Rendering for status and plan: one row function, one table, one header for
# the run. Each state word is one the events or the plan already use, so a row
# here and a line in aih log name the same thing the same way. Nothing here
# decides anything; the schedule is ai_harness_plan and the loop is lib/run.sh.

ai_harness_render_age() {
	if [ "$1" -lt 60 ]; then
		printf '%ss\n' "$1"
	elif [ "$1" -lt 3600 ]; then
		printf '%sm\n' "$(($1 / 60))"
	else
		printf '%sh%sm\n' "$(($1 / 3600))" "$((($1 % 3600) / 60))"
	fi
}

# Seconds since the epoch of a UTC ISO time, in awk: date -d is GNU and
# date -j -f is BSD, and neither is portable. Days-from-civil, so no table.
ai_harness_render_epoch() {
	printf '%s\n' "$1" | awk -F'[-T:Z]' 'NF >= 6 {
		y = $1 + 0; m = $2 + 0; d = $3 + 0
		if (m <= 2) { y--; m += 12 }
		era = int(y / 400)
		yoe = y - era * 400
		doy = int((153 * (m - 3) + 2) / 5) + d - 1
		doe = yoe * 365 + int(yoe / 4) - int(yoe / 100) + doy
		print (era * 146097 + doe - 719468) * 86400 + $4 * 3600 + $5 * 60 + $6
	}'
}

# A path under the main worktree, printed relative to it.
ai_harness_render_path() {
	_sp_root="$(ai_harness_main_worktree)/"
	case $1 in
	"$_sp_root"*) printf '%s\n' "${1#"$_sp_root"}" ;;
	*) printf '%s\n' "$1" ;;
	esac
}

# "pid <pid>, <age>" for a live agent record.
ai_harness_render_agent() {
	printf 'pid %s, %s' "$(ai_harness_kv_get "$1" pid)" \
		"$(ai_harness_render_age $(($(date -u '+%s') - $(ai_harness_kv_get "$1" epoch))))"
}

# One row: rank, seq, flag, stem, state, since, detail — tab-separated. $2 is
# the plan to read an unclaimed todo's fate from, $3 the row's place in input
# order. Rank orders the table: finished work first, then what needs a human,
# then what is moving, then what waits.
ai_harness_render_row() {
	_sr_c=$(ai_harness_claim_file "$1")
	_sr_flag=' ' _sr_rank=9 _sr_state=- _sr_detail=
	_sr_since=$(awk -v s="$1" '$2 == s { t = $1 } END { if (t) { sub(/^.*T/, "", t); print substr(t, 1, 5) } }' "$_st_ev" 2>/dev/null)
	if [ -f "$_sr_c" ]; then
		_sr_note=
		[ -d "$(ai_harness_kv_get "$_sr_c" worktree)" ] || _sr_note='; ! worktree is gone: aih doctor --repair'
		_sr_pk="$(ai_harness_ig_file parked)/$1"
		_sr_pend=$(ai_harness_ig_file integrate/pending)
		_sr_w=$(ai_harness_agent_file "$1" worker)
		_sr_r=$(ai_harness_agent_file "$1" reviewer)
		if [ -f "$_sr_pk" ]; then
			_sr_rank=1 _sr_flag='!' _sr_state=parked
			_sr_detail="$(ai_harness_kv_get "$_sr_pk" code): $(ai_harness_kv_get "$_sr_pk" detail)"
		elif [ -f "$_sr_pend" ] && [ "$(ai_harness_kv_get "$_sr_pend" stem)" = "$1" ]; then
			if [ -f "$_sr_r.lost" ]; then
				_sr_rank=1 _sr_flag='!' _sr_state=lost
				_sr_detail="reviewer exit $(ai_harness_kv_get "$_sr_r" exit) with the judgment pending: aih dispatch reviewer --detach, or integrate --continue --park"
			elif [ -f "$_sr_r" ] && ai_harness_agent_alive "$_sr_r"; then
				_sr_rank=2 _sr_state=submitted
				_sr_detail="judgment needed, reviewer $(ai_harness_render_agent "$_sr_r")"
			elif [ "$(ai_harness_kv_get "$_sr_pend" phase)" = judge ]; then
				_sr_rank=2 _sr_state=submitted
				_sr_detail='judgment needed: aih dispatch reviewer, or integrate --continue'
			else
				_sr_rank=1 _sr_flag='!' _sr_state=submitted
				_sr_detail="integrate stopped mid-$(ai_harness_kv_get "$_sr_pend" phase); the pending file needs a human"
			fi
		elif [ -f "$(ai_harness_ig_file submitted)/$1" ]; then
			_sr_rank=2 _sr_state=submitted _sr_detail='awaits integrate --next'
		elif [ ! -f "$_sr_w" ]; then
			_sr_rank=4 _sr_state=claimed _sr_detail="by $(ai_harness_kv_get "$_sr_c" agent)"
		elif ai_harness_agent_alive "$_sr_w"; then
			_sr_rank=3 _sr_state=dispatched _sr_detail="worker $(ai_harness_render_agent "$_sr_w")"
		else
			_sr_rank=1 _sr_flag='!' _sr_state=exited
			_sr_detail="worker exit $(ai_harness_kv_get "$_sr_w" exit) without submitting: inspect $(ai_harness_render_path "$(ai_harness_kv_get "$_sr_w" log)"), then abandon or dispatch by hand"
		fi
		_sr_detail="$_sr_detail$_sr_note"
	elif [ -f "$(ai_harness_todo_file "$1")" ]; then
		_sr_since=
		_sr_line=$(printf '%s\n' "$2" | awk -F'\t' -v s="$1" '($1 == "run" || $1 == "hold") && $2 == s { print $1 "\t" $3; exit }')
		case ${_sr_line%%"$_st_tab"*} in
		run) _sr_rank=5 _sr_state=runnable ;;
		hold) _sr_rank=6 _sr_state=held _sr_detail=${_sr_line#*"$_st_tab"} ;;
		*) _sr_rank=6 _sr_state=held _sr_detail='not in this run' ;;
		esac
	else
		_sr_line=$(awk -v s="$1" '$2 == s { d = ""; for (i = 5; i <= NF; i++) d = d (i > 5 ? " " : "") $i; l = $4 "\t" d } END { if (l) print l }' "$_st_ev" 2>/dev/null)
		_sr_rank=0
		if [ -n "$_sr_line" ]; then
			_sr_state=${_sr_line%%"$_st_tab"*} _sr_detail=${_sr_line#*"$_st_tab"}
		else
			_sr_detail='no todo file, no claim, no event'
		fi
	fi
	printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$_sr_rank" "$3" "$_sr_flag" "$1" "$_sr_state" "$_sr_since" "$_sr_detail"
}

# Rows for the stems on stdin, in rank order, then table order. $1 is the plan.
ai_harness_render_rows() {
	_sw_n=0
	while read -r _sw_s; do
		[ -n "$_sw_s" ] || continue
		_sw_n=$((_sw_n + 1))
		ai_harness_render_row "$_sw_s" "$1" "$_sw_n"
	done | sort -t "$_st_tab" -k1,1n -k2,2n | cut -f3-
}

# Render "flag stem state <col3> detail" rows as one table; $1 names the third
# column, SINCE unless a caller says otherwise. Columns are sized from the
# data; a DETAIL wider than what is left of 100 columns wraps onto lines
# indented under it, word by word, rather than being cut.
ai_harness_render_table() {
	awk -F'\t' -v max=100 -v c3="${1:-SINCE}" '
	function wrap(text, width, indent,   n, w, i, line, out) {
		n = split(text, w, " ")
		line = ""; out = ""
		for (i = 1; i <= n; i++) {
			if (line == "") line = w[i]
			else if (length(line) + 1 + length(w[i]) <= width) line = line " " w[i]
			else { out = out line "\n" indent; line = w[i] }
		}
		return out line
	}
	{
		flag[NR] = $1; stem[NR] = $2; state[NR] = $3; third[NR] = $4; detail[NR] = $5
		if (length($2) > w1) w1 = length($2)
		if (length($3) > w2) w2 = length($3)
		if (length($4) > w3) w3 = length($4)
		n = NR
	}
	END {
		if (w1 < 4) w1 = 4
		if (w2 < 5) w2 = 5
		if (w3 < length(c3)) w3 = length(c3)
		col = 2 + w1 + 2 + w2 + 2 + w3 + 2
		width = max - col
		if (width < 24) width = 24
		indent = sprintf("%*s", col, "")
		printf "  %-*s  %-*s  %-*s  %s\n", w1, "TODO", w2, "STATE", w3, c3, "DETAIL"
		for (i = 1; i <= n; i++) {
			line = sprintf("%s %-*s  %-*s  %-*s  %s", flag[i], w1, stem[i], w2, state[i], w3, third[i], wrap(detail[i], width, indent))
			sub(/[ \t]+$/, "", line)
			print line
		}
	}'
}

ai_harness_render_todo_stems() {
	for _ts_f in todo/*.md; do
		[ -f "$_ts_f" ] && [ "$(basename -- "$_ts_f")" != README.md ] && basename -- "$_ts_f" .md
	done
	ai_harness_claim_stems
}

# The run block: two header lines, a paused line when there is one, then the
# set's rows. Prints the rows for $1, the set's stems.
ai_harness_render_run() {
	_st_start=$(awk '$2 == "@run" && $4 == "started" { n = NR; t = $1 } END { if (n) print n, t }' "$_st_ev" 2>/dev/null)
	_st_n=${_st_start%% *}
	_st_t0=${_st_start#* }
	_st_end=$(awk -v n="${_st_n:-0}" 'NR > n && $2 == "@run" && ($4 == "stopped" || $4 == "idle") {
		d = ""; for (i = 5; i <= NF; i++) d = d (i > 5 ? " " : "") $i; e = $4 "\t" $1 "\t" d }
		END { if (e) print e }' "$_st_ev" 2>/dev/null)

	_st_rows=$(printf '%s\n' "$1" | ai_harness_render_rows "$(ai_harness_run_plan)")
	_st_count=$(printf '%s\n' "$_st_rows" | grep -c .)

	_st_e0=$(ai_harness_render_epoch "$_st_t0")
	printf 'run      %s (Total: %s)' "$(ai_harness_run_set_names)" "$_st_count"
	[ -z "$_st_start" ] || printf ', started %s UTC' "$(printf '%s' "$_st_t0" | sed 's/T/ /; s/Z$//')"

	if [ -n "$_st_end" ]; then
		_st_kind=${_st_end%%"$_st_tab"*}
		_st_rest=${_st_end#*"$_st_tab"}
		_st_when=${_st_rest%%"$_st_tab"*}
		_st_why=${_st_rest#*"$_st_tab"}
		[ -z "$_st_e0" ] || printf ', ran %s' "$(ai_harness_render_age $(($(ai_harness_render_epoch "$_st_when") - _st_e0)))"
		printf '\n'
		# The loop's own exit codes, read back from the only place it recorded
		# them (verbs/run.sh). A stop by aih stop killed it, so it had none.
		case $_st_kind:$_st_why in
		idle:*) _st_rc=", rc $EX_OK:" ;;
		stopped:'paused and drained') _st_rc=", rc $EX_PAUSED:" ;;
		stopped:'by aih stop') _st_rc= ;;
		*) _st_rc=", rc $EX_FAIL:" ;;
		esac
		_st_when=${_st_when#*T}
		printf 'loop     %s at %s%s %s\n' "$_st_kind" "${_st_when%Z}" "$_st_rc" "$_st_why"
	elif _st_pid=$(ai_harness_run_live_pid); then
		[ -z "$_st_e0" ] || printf ', %s ago' "$(ai_harness_render_age $(($(date -u '+%s') - _st_e0)))"
		printf '\nloop     pid %s alive' "$_st_pid"
		_st_log="$(ai_harness_state_dir)/log/run.log"
		[ ! -f "$_st_log" ] || printf ', log %s' "$(ai_harness_render_path "$_st_log")"
		printf '\n'
	elif _st_pid=$(ai_harness_run_holder_pid) && [ -n "$_st_pid" ] && [ "$_st_pid" != "$$" ]; then
		printf '\nloop     pid %s dead, no stop recorded\n' "$_st_pid"
	else
		printf '\nloop     no stop recorded\n'
	fi
	ai_harness_render_paused
	printf '\n'
	printf '%s\n' "$_st_rows" | ai_harness_render_table
}

# The paused line, when a pause is set.
ai_harness_render_paused() {
	_rp_f="$(ai_harness_state_dir)/PAUSED"
	[ ! -f "$_rp_f" ] || printf 'paused   "%s" until aih resume\n' "$(cat "$_rp_f")"
}

# The stems of an every-todo run: what is in todo/ and claimed now, plus what
# merged since the loop started, since a merged todo has left both.
ai_harness_render_run_stems() {
	_rs_n=$(awk '$2 == "@run" && $4 == "started" { n = NR } END { print n + 0 }' "$_st_ev" 2>/dev/null)
	{
		ai_harness_render_todo_stems
		awk -v n="${_rs_n:-0}" 'NR > n && ($4 == "merged" || $4 == "landed") { print $2 }' "$_st_ev" 2>/dev/null
	} | awk 'NF && !seen[$0]++'
}

# Every todo and claim that is not in $1, a set of stems one per line. A case
# inside $( ) trips bash 3.2 on the pattern's ")", hence a function.
ai_harness_render_outside() {
	_so_set="$_st_tab$(printf '%s' "$1" | tr '\n' "$_st_tab")$_st_tab"
	for _so_s in $(ai_harness_render_todo_stems | awk 'NF && !seen[$0]++'); do
		case $_so_set in
		*"$_st_tab$_so_s$_st_tab"*) ;;
		*) printf '%s\n' "$_so_s" ;;
		esac
	done
}

# What every renderer here needs set first: the events file, a tab, and a
# reap so exits are in the records before any row reads them.
ai_harness_render_init() {
	ai_harness_agents_reap
	_st_ev="$(ai_harness_state_dir)/events"
	_st_tab=$(printf '\t')
}

ai_harness_render_status() {
	ai_harness_render_init

	if [ -f "$(ai_harness_run_file set)" ]; then
		_st_set=$(ai_harness_run_set)
		[ -n "$_st_set" ] || _st_set=$(ai_harness_render_run_stems)
		ai_harness_render_run "$_st_set"
		_st_out=$(ai_harness_render_outside "$_st_set")
		printf '\n'
		if [ -z "$_st_out" ]; then
			printf 'outside this run: none\n'
		else
			_st_rows=$(printf '%s\n' "$_st_out" | ai_harness_render_rows "$(ai_harness_plan)")
			printf 'outside this run (Total: %s)\n' "$(printf '%s\n' "$_st_rows" | grep -c .)"
			printf '%s\n' "$_st_rows" | ai_harness_render_table
		fi
	else
		printf 'no run yet. aih run --all starts one; aih plan shows what it would do.\n\n'
		_st_rows=$(ai_harness_render_todo_stems | awk 'NF && !seen[$0]++' | ai_harness_render_rows "$(ai_harness_plan)")
		[ -z "$_st_rows" ] || printf '%s\n' "$_st_rows" | ai_harness_render_table
	fi

	# The run lock is the loop line's business while its holder is alive.
	for _st_l in "$(ai_harness_state_dir)"/lock/*; do
		[ -d "$_st_l" ] || continue
		_st_name=$(basename -- "$_st_l")
		[ "$_st_name" != run ] || ! ai_harness_run_live_pid >/dev/null || continue
		printf '\nlock %s %s\n' "$_st_name" "$(ai_harness_lock_who "$_st_name")"
		ai_harness_lock_is_stale "$_st_name" && printf '  ! stale: inspect, then aih unlock %s --force\n' "$_st_name"
	done
	return 0
}
