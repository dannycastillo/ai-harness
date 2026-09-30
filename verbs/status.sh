# status — the run in progress or the last one, then every todo outside it
#
# usage: aih status
#
# Prints the loop, a row per todo with its state and why, and the claims,
# agents and queue. Read-only.
#
# Runs: the trunk checkout or a claim's worktree.

[ $# -eq 0 ] || die "$EX_USAGE" "usage: aih status"

ai_harness_render_status
