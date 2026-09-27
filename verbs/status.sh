# status — the run in progress or the last one, then every todo outside it
#
#   aih status

[ $# -eq 0 ] || die "$EX_USAGE" "usage: aih status"

ai_harness_status
