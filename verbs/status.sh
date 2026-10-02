# status — the run in progress or the last one, then every todo outside it
#
# usage: aih status
#
# Prints the loop, a row per todo with its state and why, and the claims,
# agents and queue. Read-only.
#
# Runs: anywhere. From a trunk checkout or a claim's worktree it reports that
# tree; from any other checkout it lists every active trunk and each one's
# status.

[ $# -eq 0 ] || die "$EX_USAGE" "$(ai_harness_usage_line status)"

if ! ai_harness_here_is_trunk_or_claim; then
	_trunks=$(ai_harness_trunk_checkouts)
	[ -n "$_trunks" ] || ai_harness_die_no_active_trunk status
	ai_harness_report_begin
	printf 'aih: %s\n\nACTIVE TRUNKS\n' "$(ai_harness_no_trunk_branch_line)"
	_n=0
	_rc=$EX_OK
	while IFS='	' read -r _tb _tp; do
		_n=$((_n + 1))
		printf '\n%s. %s\n' "$_n" "$_tp"
		_out=$(cd -- "$_tp" && "$AI_HARNESS_HOME/bin/aih" status 2>&1) || _rc=$EX_FAIL
		printf '%s\n' "$_out" | sed '1{/^$/d;}'
	done <<TRUNKS
$_trunks
TRUNKS
	exit "$_rc"
fi

ai_harness_report_begin
ai_harness_render_status

