# Reading and validating one todo file.

ai_harness_todo_file() { printf 'todo/%s.md\n' "$1"; }

# The value of a "- **Field:** value" line.
ai_harness_todo_field() { sed -n "s/^- \*\*$2:\*\* *//p" "$1" | head -1; }

# todo/<prefix>-<kebab>.md is branch <prefix>/<kebab>. Split on the declared
# prefixes rather than the first hyphen, since a kebab description contains
# hyphens too.
ai_harness_todo_branch_from_stem() {
	for _p in $AI_HARNESS_PREFIXES; do
		case $1 in
		"$_p"-*)
			printf '%s/%s\n' "$_p" "${1#"$_p"-}"
			return 0
			;;
		esac
	done
	return 1
}

# Whether a todo file's Priority and Touches fields are well-formed. Split
# out of ai_harness_todo_validate so verbs/plan.sh's inbox count can hold a
# filed-but-not-promoted todo to the same bar.
ai_harness_todo_fields_ok() {
	_tf_f=$1
	_tf_bad=0
	case $(ai_harness_todo_field "$_tf_f" Priority) in
	high | medium | low) ;;
	*) warn "$_tf_f: Priority must be high, medium or low"; _tf_bad=1 ;;
	esac

	[ -n "$(ai_harness_todo_field "$_tf_f" Touches)" ] || {
		warn "$_tf_f: Touches is empty — it reserves nothing"
		_tf_bad=1
	}

	[ "$_tf_bad" -eq 0 ]
}

# Only a flat todo/<stem>.md is the backlog (AGENTS.md: todo/new/ is the
# inbox). A stem that resolves under any subdirectory of todo/ instead is
# filed but not promoted, whatever name it's asked for under.
ai_harness_todo_validate() {
	_stem=$1
	_base=${_stem##*/}
	_f=$(ai_harness_todo_file "$_base")

	if [ ! -f "$_f" ]; then
		_nested=$(find todo -mindepth 2 -name "$_base.md" 2>/dev/null | head -1)
		if [ -n "$_nested" ]; then
			_dir=${_nested#todo/}
			_dir=${_dir%/*}
			warn "$_base is in todo/$_dir/, not ready: git mv todo/$_dir/$_base.md todo/ to make it ready"
			return 1
		fi
		warn "no such todo: $_f"
		return 1
	fi

	ai_harness_todo_branch_from_stem "$_base" >/dev/null || {
		warn "$_f: '$_base' starts with no declared prefix ($AI_HARNESS_PREFIXES)"
		return 1
	}

	ai_harness_todo_fields_ok "$_f"
}
