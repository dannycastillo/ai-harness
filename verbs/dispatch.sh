# dispatch — claim a todo and start an agent in its worktree
#
#   aih dispatch worker [<todo-stem>] [--agent <name>] [--print] [--detach]
#   aih dispatch reviewer [--print] [--detach]
#
# Attached, stdout is shell, so this leaves you where the agent runs:
#   eval "$(aih dispatch worker)"
# With AI_HARNESS_AGENT_CMD unset it prints the cd, and the boot prompt on stderr.
# --detach starts the agent under nohup, records it in agents/, prints its pid.
# --print prints the boot prompt and exits, claiming nothing and touching no
# state — worker needs a named todo-stem in place of what claim would give it;
# reviewer needs no pending packet in place of what --next would give it.

_usage="usage: aih dispatch worker [<todo-stem>] [--agent <name>] [--print] [--detach] | reviewer [--print] [--detach]"
[ $# -gt 0 ] || die "$EX_USAGE" "$_usage"
_role=$1
shift
_detach=no
_print=no
_n=$#
while [ "$_n" -gt 0 ]; do
	case $1 in
	--detach) _detach=yes ;;
	--print) _print=yes ;;
	*) set -- "$@" "$1" ;;
	esac
	shift
	_n=$((_n - 1))
done
[ "$_detach" = no ] || [ -n "${AI_HARNESS_AGENT_CMD:-}" ] ||
	die "$EX_USAGE" "dispatch: --detach needs AI_HARNESS_AGENT_CMD set in .ai-harness.conf"
[ "$_print" = no ] || [ "$_detach" = no ] ||
	die "$EX_USAGE" "dispatch: --print and --detach don't combine"

case $_role in
worker)
	if [ "$_print" = yes ]; then
		_stem=${1:-}
		[ -n "$_stem" ] || die "$EX_USAGE" "dispatch: worker --print needs a todo-stem"
		shift
		[ $# -eq 0 ] || die "$EX_USAGE" "$_usage"
		_stem=${_stem#todo/}
		_stem=${_stem%.md}
		ai_harness_todo_validate "$_stem" || die "$EX_FAIL" "dispatch: $_stem did not validate"
		git cat-file -e "$AI_HARNESS_TRUNK:$(ai_harness_todo_file "$_stem")" 2>/dev/null ||
			die "$EX_FAIL" "dispatch: $(ai_harness_todo_file "$_stem") is not on $AI_HARNESS_TRUNK yet"
		_wt="$(ai_harness_worktree_root)/$_stem"
	else
		case ${1:-} in
		"" | -*) set -- --next "$@" ;;
		esac
		_wt=$("$AI_HARNESS_HOME/bin/aih" claim "$@") || exit $?
	fi
	_stem=$(basename -- "$_wt")
	_prompt="You are an AI Harness worker in this worktree. Your todo is todo/$_stem.md. \
Read AGENTS.md in full; if it has a section headed \`## ai-harness\`, those \
instructions extend your role. Then run \`aih role protocol\` and \`aih role worker\` \
and follow them, then your todo. aih gate --full must be green before you finish. \
Do not merge and do not push: when Done when is satisfied, end with aih submit, \
then report what you did and how each box is met."
	;;
reviewer)
	[ $# -eq 0 ] || die "$EX_USAGE" "$_usage"
	if [ "$_print" = yes ]; then
		_stem="<todo-stem>"
	else
		_p=$(ai_harness_ig_file integrate/pending)
		[ "$(ai_harness_kv_get "$_p" phase || :)" = judge ] ||
			die "$EX_FAIL" "dispatch: nothing awaits a verdict — integrate --next first"
		_wt=$(ai_harness_trunk_worktree)
		[ "$AI_HARNESS_REPO" = "$_wt" ] ||
			die "$EX_USAGE" "dispatch: run it from the $AI_HARNESS_TRUNK checkout (${_wt:-none exists})"
		_stem=$(ai_harness_kv_get "$_p" stem)
	fi
	_prompt="You are an AI Harness reviewer in this $AI_HARNESS_TRUNK checkout. aih integrate --next \
has stopped for your judgment on $_stem; the packet is at $(ai_harness_ig_file integrate/packet). \
Read AGENTS.md in full; if it has a section headed \`## ai-harness\`, those \
instructions extend your role. Then run \`aih role protocol\` and \`aih role reviewer\` \
and follow them, then the packet. Verify every box as the packet says, then run \
exactly one aih integrate --continue command and stop: do not run integrate --next, \
since the loop starts a new reviewer for the next packet."
	;;
*) die "$EX_USAGE" "$_usage" ;;
esac

[ "$_print" = no ] || { printf '%s\n' "$_prompt"; exit "$EX_OK"; }

_q() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"; }

if [ "$_detach" = yes ]; then
	cd "$_wt" || die "$EX_FAIL" "dispatch: cannot cd to $_wt"
	_pid=$(ai_harness_agent_spawn "$_role" "$_stem" "$_prompt") ||
		die "$EX_FAIL" "dispatch: $_stem already has a $_role record — aih status"
	log "dispatch: $_role $_stem pid $_pid, log $(ai_harness_agent_log "$_stem" "$_role")"
	printf '%s\n' "$_pid"
elif [ -z "${AI_HARNESS_AGENT_CMD:-}" ]; then
	printf 'cd %s\n' "$(_q "$_wt")"
	log "dispatch: AI_HARNESS_AGENT_CMD is unset — start a $_role in $_wt with:"
	log "$_prompt"
elif [ -t 1 ]; then
	cd "$_wt" || die "$EX_FAIL" "dispatch: cannot cd to $_wt"
	# shellcheck disable=SC2086  # the command may carry its own arguments
	exec $AI_HARNESS_AGENT_CMD "$_prompt"
else
	printf 'cd %s && %s %s\n' "$(_q "$_wt")" "$AI_HARNESS_AGENT_CMD" "$(_q "$_prompt")"
fi
