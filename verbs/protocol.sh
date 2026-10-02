# protocol — print the shared rules every role begins with
#
# usage: aih protocol
#
# Prints roles/protocol.md from the installed tree: branches, commits, todos,
# Touches and how agents work in parallel. aih role worker|reviewer prints it
# again ahead of the role.
#
# Runs: anywhere, repository or not. Writes nothing.

ai_harness_report_begin
cat "$AI_HARNESS_HOME/roles/protocol.md"
