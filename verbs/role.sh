# role — print a role doc from the tree, for aih role protocol|worker|reviewer
#
# usage: aih role protocol|worker|reviewer
#
# Prints roles/<role>.md from the installed tree. protocol is the rules every
# role shares; worker and reviewer are that role's sequence. Boot prompts and
# adapters say aih role, never a path.
#
# Runs: the trunk checkout or a claim's worktree. Writes nothing.

[ $# -eq 1 ] || die "$EX_USAGE" "$(ai_harness_usage_line role)"

case $1 in
protocol | worker | reviewer)
	cat "$AI_HARNESS_HOME/roles/$1.md"
	;;
*) die "$EX_USAGE" "role: unknown role: $1 (try: protocol, worker, reviewer)" ;;
esac
