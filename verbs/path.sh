# path — print a claim's worktree, for cd "$(aih path <todo>)"
#
# usage: aih path <todo-stem>
#
# Prints the worktree the claim recorded and nothing else. Fails when the
# todo is not claimed or the recorded directory is gone (aih doctor --repair).
#
# Runs: the trunk checkout or a claim's worktree. Writes nothing.

[ $# -eq 1 ] || die "$EX_USAGE" "$(ai_harness_usage_line path)"
_stem=${1#todo/}
_stem=${_stem%.md}
_c=$(ai_harness_claim_file "$_stem")
[ -f "$_c" ] || die "$EX_FAIL" "path: $_stem is not claimed"
_wt=$(ai_harness_kv_get "$_c" worktree)
[ -d "$_wt" ] || die "$EX_FAIL" "path: $_wt is recorded but gone — aih doctor --repair"
printf '%s\n' "$_wt"
