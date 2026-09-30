# pause — stop dispatching; what is queued still merges, what runs still runs
#
# usage: aih pause "<reason>"
#
# Writes the reason to the state directory's PAUSED file. claim, dispatch and
# run then refuse new work with exit 3, and integrate keeps merging what is
# already submitted. aih resume lifts it.
#
# Runs: the trunk checkout or a claim's worktree.

[ $# -eq 1 ] && [ -n "$1" ] || die "$EX_USAGE" "$(ai_harness_usage_line pause)"
_f="$(ai_harness_state_dir)/PAUSED"
mkdir -p "$(dirname -- "$_f")"
printf '%s\n' "$1" >"$_f"
ai_harness_event @run - paused "$1"
log "pause: no new claims until aih resume — $1"
