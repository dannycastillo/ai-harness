# role — print the shared rules and then one role's sequence
#
# usage: aih role worker|reviewer
#
# Prints roles/protocol.md, a blank line, then roles/<role>.md from the
# installed tree. Boot prompts and adapters say aih role, never a path.
#
# Runs: anywhere, repository or not. Writes nothing.

[ $# -eq 1 ] || die "$EX_USAGE" "$(ai_harness_usage_line role)"

case $1 in
worker | reviewer)
	cat "$AI_HARNESS_HOME/roles/protocol.md"
	printf '\n'
	cat "$AI_HARNESS_HOME/roles/$1.md"
	;;
protocol) die "$EX_USAGE" "role: protocol is its own verb: aih protocol" ;;
*) die "$EX_USAGE" "role: unknown role: $1 (try: worker, reviewer)" ;;
esac
