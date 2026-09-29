# The assertion the whole coordination layer rests on, checked automatically.
#
# ADR-10 puts state under --git-common-dir so every worktree sees one copy.
# That fails silently when it is wrong, and from the main worktree --git-dir,
# --git-path and --git-common-dir all return ".git" — so a slip passes every
# test run from the root and first appears once a second worker exists.

# Prints its own result lines. Non-zero means the assertion failed.
ai_harness_selftest() {
	_tmp=$(mktemp -d) || {
		printf '    %-11s %s\n' cleanup 'could not make a temp directory'
		return 1
	}
	_wt="$_tmp/linked"
	_rc=0

	if git worktree add --detach "$_wt" HEAD >/dev/null 2>&1; then
		_here=$(ai_harness_state_dir)
		_there=$(cd "$_wt" && "$AI_HARNESS_HOME/bin/aih" doctor --print-state-dir) ||
			_there="(the linked worktree's harness failed)"
		if [ "$_here" = "$_there" ]; then
			printf '    %-11s %s\n' 'state dir' 'identical from a linked worktree'
		else
			printf '    %-11s %s\n' 'state dir' "root: $_here / linked: $_there"
			_rc=1
		fi
		if ai_harness_state_worktree_claim "$_wt" selftest/no-such-todo >/dev/null; then
			printf '    %-11s %s\n' 'claim rule' 'accepted a worktree whose branch has no todo'
			_rc=1
		else
			printf '    %-11s %s\n' 'claim rule' 'rejects a worktree with no todo on trunk'
		fi
		git worktree remove --force "$_wt" >/dev/null 2>&1 || {
			printf '    %-11s %s\n' cleanup "could not remove $_wt"
			_rc=1
		}
		git worktree prune
	else
		printf '    %-11s %s\n' worktree 'could not create a throwaway worktree'
		_rc=1
	fi

	rm -rf "$_tmp"
	return "$_rc"
}
