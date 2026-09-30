# resume — lift a pause
#
# usage: aih resume
#
# Removes the PAUSED file, so claim, dispatch and run take new work again.
# Exits 0 when there was no pause.
#
# Runs: the trunk checkout or a claim's worktree.

[ $# -eq 0 ] || die "$EX_USAGE" 'usage: aih resume'
_f="$(ai_harness_state_dir)/PAUSED"
[ -f "$_f" ] || die "$EX_OK" "resume: not paused"
rm -f "$_f"
ai_harness_event @run - resumed ""
log "resume: claims allowed again"
