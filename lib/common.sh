# Shared helpers. Sourced by bin/aih before any verb.
#
# POSIX sh only: macOS ships bash 3.2.57, so no arrays and no mapfile.

# shellcheck disable=SC2034  # read by verbs, which are sourced at runtime
EX_OK=0
EX_FAIL=1
EX_USAGE=2
EX_PAUSED=3
# The environment cannot run the gate, as distinct from the gate failing.
# integrate must not blame a branch for a misconfigured machine.
EX_CONFIG=4
EX_JUDGE=10

log()  { printf '%s\n' "$*" >&2; }
warn() { printf 'aih: %s\n' "$*" >&2; }

die() {
	_c=$1
	shift
	printf 'aih: %s\n' "$*" >&2
	exit "$_c"
}

# The coordination state directory, shared by every worktree and structurally
# untrackable by git (ADR-10).
#
# --git-common-dir, never --git-dir or --git-path: those two are per-worktree
# for this name, and all three spellings return ".git" from the main worktree.
# A slip here passes every test run from the root and first breaks once a second
# worker exists, silently, by giving each worker a private claims directory.
ai_harness_state_dir() {
	_d=$(git rev-parse --git-common-dir) || return 1
	case $_d in
	/*) ;;
	*) _d=$(CDPATH='' cd -- "$_d" && pwd -P) ;;
	esac
	printf '%s/ai-harness\n' "$_d"
}

# The main worktree: the one holding .git itself. Relative paths in
# .ai-harness.conf resolve against this rather than the current worktree, which
# would otherwise nest AI_HARNESS_WORKTREE_ROOT inside itself one level down.
ai_harness_main_worktree() {
	_d=$(git rev-parse --git-common-dir) || return 1
	case $_d in
	/*) ;;
	*) _d=$(CDPATH='' cd -- "$_d" && pwd -P) ;;
	esac
	dirname -- "$_d"
}

ai_harness_worktree_root() {
	case $AI_HARNESS_WORKTREE_ROOT in
	/*) _r=$AI_HARNESS_WORKTREE_ROOT ;;
	*) _r="$(ai_harness_main_worktree)/$AI_HARNESS_WORKTREE_ROOT" ;;
	esac
	# It need not exist yet, so normalize the parent and keep the leaf. The
	# parent itself must already exist: cd-ing into a missing one used to
	# collapse silently, turning the root into "/<leaf>".
	_parent=$(dirname -- "$_r")
	if _resolved=$(CDPATH='' cd -- "$_parent" 2>/dev/null && pwd -P); then
		printf '%s/%s\n' "$_resolved" "$(basename -- "$_r")"
		return 0
	fi
	ai_harness_nearest_existing "$_parent"
	return 1
}

# The nearest ancestor of a path that exists, resolved, with the missing rest
# reattached unresolved. Callers use it to name what is missing rather than
# printing the un-collapsed, harder-to-read path they started with.
ai_harness_nearest_existing() {
	_p=$1
	_suffix=
	while [ "$_p" != / ] && [ "$_p" != . ]; do
		if _abs=$(CDPATH='' cd -- "$_p" 2>/dev/null && pwd -P); then
			printf '%s%s\n' "$_abs" "${_suffix:+/$_suffix}"
			return 0
		fi
		_suffix=$(basename -- "$_p")${_suffix:+/$_suffix}
		_p=$(dirname -- "$_p")
	done
	printf '%s\n' "$1"
}

# Where trunk is checked out, discovered rather than assumed. Empty when trunk
# is not checked out anywhere.
ai_harness_trunk_worktree() {
	git worktree list --porcelain | awk -v b="refs/heads/$AI_HARNESS_TRUNK" '
		/^worktree /  { p = substr($0, 10) }
		$0 == "branch " b { print p; exit }
	'
}

ai_harness_is_defined() { command -v "$1" >/dev/null 2>&1; }
