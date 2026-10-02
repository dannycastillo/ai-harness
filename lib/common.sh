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

# Whether a path is the worktree of some claim. Claim files are parsed, never
# sourced (state.sh).
ai_harness_is_claim_worktree() {
	_icw_p=$(CDPATH='' cd -- "$1" 2>/dev/null && pwd -P) || return 1
	for _icw_f in "$(ai_harness_state_dir)"/claims/*; do
		[ -f "$_icw_f" ] || continue
		_icw_w=$(ai_harness_kv_get "$_icw_f" worktree)
		[ -n "$_icw_w" ] || continue
		_icw_w=$(CDPATH='' cd -- "$_icw_w" 2>/dev/null && pwd -P) || continue
		[ "$_icw_w" != "$_icw_p" ] || return 0
	done
	return 1
}

# Every checkout whose config names its own branch as trunk, one
# "<branch><TAB><path>" per line. Claim worktrees carry the same config on
# other branches, so they do not count.
ai_harness_trunk_checkouts() {
	git worktree list --porcelain | awk '
		/^worktree / { p = substr($0, 10) }
		/^branch refs\/heads\// { print p "\t" substr($0, 19) }
	' | while IFS='	' read -r _tc_p _tc_b; do
		_tc_t=$(sed -n 's/^AI_HARNESS_TRUNK="\(.*\)"$/\1/p' "$_tc_p/.ai-harness.conf" 2>/dev/null | head -1)
		if [ "$_tc_t" = "$_tc_b" ]; then
			printf '%s\t%s\n' "$_tc_b" "$_tc_p"
		fi
	done
}

# The one trunk checkout, or failure on none or several.
ai_harness_sole_trunk_checkout() {
	_stc=$(ai_harness_trunk_checkouts)
	case $_stc in
	'' | *'
'*) return 1 ;;
	esac
	printf '%s\n' "$_stc"
}

# "this branch (<b>) does not have an active aih trunk."
ai_harness_no_trunk_branch_line() {
	_nbl=$(git symbolic-ref --short -q HEAD || git rev-parse --short HEAD)
	printf 'this branch (%s) does not have an active aih trunk.\n' "$_nbl"
}

# Whether the tree we run in is a trunk checkout or a claim's worktree. Reads
# git and the state dir, never the conf.
ai_harness_here_is_trunk_or_claim() {
	_hit=$(CDPATH='' cd -- "$AI_HARNESS_REPO" && pwd -P)
	ai_harness_is_claim_worktree "$_hit" && return 0
	_hit_all=$(ai_harness_trunk_checkouts)
	while IFS='	' read -r _hit_b _hit_p; do
		[ -n "$_hit_p" ] || continue
		_hit_p=$(CDPATH='' cd -- "$_hit_p" 2>/dev/null && pwd -P) || continue
		[ "$_hit_p" != "$_hit" ] || return 0
	done <<TRUNKS
$_hit_all
TRUNKS
	return 1
}

# Dies naming the branch we are on and every active trunk, with a command that
# reruns the verb there. The conf a branch carries can name a trunk that is
# gone, so this asks the worktrees, not the conf.
ai_harness_die_no_active_trunk() {
	_dnt_v=${1:-$verb}
	_dnt_all=$(ai_harness_trunk_checkouts)
	_dnt_nl='
'
	case $_dnt_all in
	'') die "$EX_FAIL" "there are no active trunks for this project; run aih init to create one." ;;
	*"$_dnt_nl"*)
		_dnt_m="$(ai_harness_no_trunk_branch_line)${_dnt_nl}Active aih trunks found:"
		while IFS='	' read -r _dnt_tb _dnt_tp; do
			_dnt_m="$_dnt_m${_dnt_nl}  $_dnt_tb: cd $_dnt_tp && aih $_dnt_v"
		done <<TRUNKS
$_dnt_all
TRUNKS
		die "$EX_FAIL" "$_dnt_m"
		;;
	esac
	_dnt_tp=${_dnt_all#*	}
	_dnt_m=$(ai_harness_no_trunk_branch_line)
	die "$EX_FAIL" "$_dnt_m${_dnt_nl}Active aih trunk found at $_dnt_tp:${_dnt_nl}  cd $_dnt_tp && aih $_dnt_v"
}

# For the verbs that only the trunk checkout may run, after the shared guard
# has let a claim worktree through.
ai_harness_require_trunk_checkout() {
	_rtc=$(ai_harness_trunk_worktree)
	[ "$AI_HARNESS_REPO" != "$_rtc" ] || return 0
	[ -z "$_rtc" ] || die "$EX_FAIL" "run it from the $AI_HARNESS_TRUNK checkout: cd $_rtc && aih $1"
	ai_harness_die_no_active_trunk "$1"
}

# Verbs read the tree they run in, so they run from the trunk checkout or a
# claim's, and anywhere else is redirected rather than guessed at.
ai_harness_require_trunk_or_claim() {
	_top=$(CDPATH='' cd -- "$AI_HARNESS_REPO" && pwd -P)
	_tw=$(ai_harness_trunk_worktree)
	if [ -n "$_tw" ]; then
		[ "$(CDPATH='' cd -- "$_tw" && pwd -P)" != "$_top" ] || return 0
	fi
	ai_harness_is_claim_worktree "$_top" && return 0
	if [ -n "$_tw" ]; then
		die "$EX_FAIL" "run this from the $AI_HARNESS_TRUNK checkout: cd $_tw"
	fi
	ai_harness_die_no_active_trunk
}

# A verb's documentation is the comment block that opens its file, printed
# with the leading "# " stripped. The block ends at the first non-comment line.
ai_harness_verb_help() {
	awk '!/^#/ { exit } { sub(/^# ?/, ""); print }' "$AI_HARNESS_HOME/verbs/$1.sh"
}

ai_harness_usage_line() {
	ai_harness_verb_help "$1" | sed -n '/^usage: /{p;q;}'
}
