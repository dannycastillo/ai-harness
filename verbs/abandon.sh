# abandon — give a claim back, freeing its todo and its paths
#
# usage: aih abandon <todo-stem> [--keep-branch] [--force]
#
# Removes the claim, its worktree and its branch, so the todo is offered again
# and its Touches are free. Refuses while the worktree has uncommitted work,
# the branch has unmerged commits, an agent is alive in it, or the branch
# is submitted and waiting for integrate; --force overrides each (it kills the
# agent and withdraws the submission). --keep-branch leaves the branch.
#
# Runs: the trunk checkout or a claim's worktree.

_stem=
_keep=no
_force=no
while [ $# -gt 0 ]; do
	case $1 in
	--keep-branch) _keep=yes ;;
	--force) _force=yes ;;
	-*) die "$EX_USAGE" "abandon: unknown option: $1" ;;
	*) _stem=$1 ;;
	esac
	shift
done
[ -n "$_stem" ] || die "$EX_USAGE" "usage: aih abandon <todo-stem> [--keep-branch] [--force]"
_stem=${_stem#todo/}
_stem=${_stem%.md}

_c=$(ai_harness_claim_file "$_stem")
[ -f "$_c" ] || die "$EX_FAIL" "abandon: $_stem is not claimed"
_branch=$(ai_harness_kv_get "$_c" branch)
_wt=$(ai_harness_kv_get "$_c" worktree)
_sub="$(ai_harness_ig_file submitted)/$_stem"
[ ! -f "$_sub" ] || [ "$_force" = yes ] ||
	die "$EX_FAIL" "abandon: $_stem is submitted and waits for integrate — let it merge, or --force withdraws it"

# A live agent may still be writing into the worktree or the shared record;
# removing either out from under it is what re-dispatch would then race with.
for _ag in "$(ai_harness_agents_dir)/$_stem".*; do
	[ -f "$_ag" ] || continue
	case $_ag in *.exit) continue ;; esac
	ai_harness_agent_alive "$_ag" || continue
	_pid=$(ai_harness_kv_get "$_ag" pid)
	if [ "$_force" = yes ]; then
		ai_harness_agent_kill "$_ag" abandoned
	else
		die "$EX_FAIL" "abandon: $_stem has a live $(ai_harness_kv_get "$_ag" role) agent, pid $_pid — stop it, or --force kills it"
	fi
done

if [ -d "$_wt" ]; then
	# Plain remove refuses when the worktree is dirty, which is exactly when
	# abandoning silently would throw away work someone still wants.
	if [ "$_force" = yes ]; then
		git worktree remove --force "$_wt" || die "$EX_FAIL" "abandon: could not remove $_wt"
	else
		git worktree remove "$_wt" ||
			die "$EX_FAIL" "abandon: $_wt has uncommitted work — inspect it, then --force"
	fi
fi
git worktree prune

if [ "$_keep" = no ]; then
	if ! git branch -d "$_branch" >/dev/null 2>&1; then
		if [ "$_force" = yes ]; then
			git branch -D "$_branch" >/dev/null 2>&1 ||
				warn "abandon: could not delete $_branch"
		else
			warn "abandon: $_branch holds unmerged commits — kept. --force deletes it"
		fi
	fi
fi

rm -f "$_c" "$_sub" "$_sub.body" "$(ai_harness_ig_file parked)/$_stem"
ai_harness_agents_clear "$_stem"
ai_harness_event "$_stem" - abandoned "$_branch"
log "abandon: $_stem released"
