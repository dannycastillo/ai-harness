# role — print a role doc from the tree, for aih role protocol|worker|reviewer

_usage="usage: aih role protocol|worker|reviewer"
[ $# -eq 1 ] || die "$EX_USAGE" "$_usage"

case $1 in
protocol | worker | reviewer)
	cat "$AI_HARNESS_HOME/roles/$1.md"
	;;
*) die "$EX_USAGE" "role: unknown role: $1 (try: protocol, worker, reviewer)" ;;
esac
