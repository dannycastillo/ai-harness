# help — list the verbs and how to invoke them
#
# usage: aih help
#
# Prints every verb with its one line, and the exit codes.
# aih <verb> --help prints one verb's documentation.
#
# Runs: anywhere, repository or not.

# The list is globbed rather than declared, so a new verb appears here for free.

ai_harness_report_begin
printf 'aih — AI Harness%s\n\n' "${AI_HARNESS_PROJECT:+ for $AI_HARNESS_PROJECT}"
printf 'verbs:\n'
for _f in "$AI_HARNESS_HOME"/verbs/*.sh; do
	_name=$(basename -- "$_f" .sh)
	_desc=$(sed -n '1s/^# [a-z-]* — //p' "$_f")
	printf '  %-12s %s\n' "$_name" "$_desc"
done

cat <<'TXT'

The tree is relocatable and installs once per machine. aih on PATH may be a
fixed path, a symlink, or a launcher; aih doctor prints one when none is on
PATH.

exit codes: 0 ok, 1 failed, 2 usage, 3 paused, 4 the environment cannot run
the gate, 10 judgment needed

aih <verb> --help says what one verb reads, writes and refuses, and where it
runs.

aih protocol is the shared rules, todos, Touches, branches and roles; read it
before running anything.
TXT
