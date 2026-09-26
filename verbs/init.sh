# init — configure a repo the harness has never seen
#
#   aih init [--yes] [--force] [--trunk <name>]
#
# Detects the stack (go.mod, package.json, Cargo.toml, pyproject.toml,
# Makefile, in that order), prints the .ai-harness.conf it would write, and
# stops for a y unless given --yes or run from a terminal. Writes the config,
# todo/README.md, and the adapters whose dot directory already exists.
# Refuses to overwrite an existing .ai-harness.conf without --force. Never
# copies the tree and never edits AGENTS.md (adr-2026-09-26-one-install-
# per-machine, adr-2026-09-26-the-protocol-ships-with-the-tree).

_yes=no
_force=no
_trunk=
while [ $# -gt 0 ]; do
	case $1 in
	--yes | -y) _yes=yes ;;
	--force) _force=yes ;;
	--trunk)
		[ $# -gt 1 ] || die "$EX_USAGE" "init: --trunk needs a name"
		_trunk=$2 && shift
		;;
	*) die "$EX_USAGE" "usage: aih init [--yes] [--force] [--trunk <name>]" ;;
	esac
	shift
done

_conf="$AI_HARNESS_REPO/.ai-harness.conf"
[ ! -f "$_conf" ] || [ "$_force" = yes ] ||
	die "$EX_FAIL" "init: $_conf already exists — use --force to overwrite"

_tmp_dir="$(ai_harness_state_dir)/tmp"
mkdir -p "$_tmp_dir"
_gates_file="$_tmp_dir/init.gates.$$"
_gateblock="$_tmp_dir/init.gateblock.$$"
_conf_out="$_tmp_dir/init.conf.$$"
: >"$_gates_file"
trap 'rm -f "$_gates_file" "$_gateblock" "$_conf_out"' EXIT

# ---------------------------------------------------------------- detection
#
# In order of preference; the first stack found wins. Each detector appends
# gate functions to $_gates_file and their names to $_gates. A gate is
# declared only for a tool that is actually present at init time, never for
# one it merely expects: a gate that cannot run is worse than no gate.

_gates=
_quick=
_detected=

_gate() { # <name> <tools> <command>
	printf 'ai_harness_gate_%s() { %s; }\n' "$1" "$3" >>"$_gates_file"
	printf 'AI_HARNESS_GATE_TOOLS_%s="%s"\n' "$1" "$2" >>"$_gates_file"
	_gates="$_gates $1"
}

_detect_go() {
	[ -f go.mod ] || return 1
	_detected=go.mod
	_gate build go 'go build ./...'
	_gate vet go 'go vet ./...'
	cat >>"$_gates_file" <<'EOF'
ai_harness_gate_fmt() {
	out=$(gofmt -l .)
	[ -z "$out" ] || {
		printf '%s\n' "$out"
		return 1
	}
}
AI_HARNESS_GATE_TOOLS_fmt="gofmt"
EOF
	_gates="$_gates fmt"
	_gate test go 'go test ./...'
	_quick="build vet"
}

# The scripts block of package.json, keys only. Good enough for a file
# written by npm or a human; a script value holding a "}" on its own line
# ends it early.
_npm_scripts() {
	sed -n '/"scripts"[[:space:]]*:/,/^[[:space:]]*}/p' package.json |
		sed '1d' | sed -n 's/^[[:space:]]*"\([^"]*\)"[[:space:]]*:.*/\1/p'
}

_detect_node() {
	[ -f package.json ] || return 1
	_detected=package.json
	_pm=npm
	[ ! -f pnpm-lock.yaml ] || _pm=pnpm
	[ ! -f yarn.lock ] || _pm=yarn
	_scripts=$(_npm_scripts)
	for _s in lint typecheck build test; do
		printf '%s\n' "$_scripts" | grep -qx "$_s" || continue
		_gate "$_s" "$_pm" "$_pm run $_s"
		case $_s in
		lint | typecheck) _quick="$_quick $_s" ;;
		build) [ -n "$_quick" ] || _quick=build ;;
		esac
	done
	_quick=${_quick# }
}

_detect_cargo() {
	[ -f Cargo.toml ] || return 1
	_detected=Cargo.toml
	_gate build cargo 'cargo build'
	! ai_harness_is_defined rustfmt || _gate fmt 'cargo rustfmt' 'cargo fmt --check'
	! ai_harness_is_defined cargo-clippy || _gate clippy 'cargo cargo-clippy' 'cargo clippy -- -D warnings'
	_gate test cargo 'cargo test'
	_quick=build
}

# Only tools the file declares a [tool.<name>] table for, so the gate
# reflects a choice the project made rather than one this script made for it.
_detect_python() {
	[ -f pyproject.toml ] || return 1
	_detected=pyproject.toml
	for _t in ruff black mypy pytest; do
		grep -q "^\[tool\.$_t\(\.\|\]\)" pyproject.toml || continue
		case $_t in
		ruff) _gate ruff ruff 'ruff check .' && _quick="$_quick ruff" ;;
		black) _gate black black 'black --check .' ;;
		mypy) _gate mypy mypy 'mypy .' && _quick="$_quick mypy" ;;
		pytest) _gate test pytest pytest ;;
		esac
	done
	_quick=${_quick# }
}

_detect_make() {
	[ -f Makefile ] || return 1
	_detected=Makefile
	for _t in build lint check fmt test; do
		grep -q "^${_t}[[:space:]]*:" Makefile || continue
		_gate "$_t" make "make $_t"
		case $_t in
		build | lint | check) _quick="$_quick $_t" ;;
		esac
	done
	_quick=${_quick# }
}

_detect_go || _detect_node || _detect_cargo || _detect_python || _detect_make || :
if [ -n "$_detected" ] && [ -z "$_gates" ]; then
	warn "$_detected found, but nothing in it names a check this recognises"
	_detected=
fi
if [ -z "$_detected" ]; then
	_detected="no recognised stack"
	cat >>"$_gates_file" <<'EOF'
# aih init found no stack it recognises: no gate is declared, and doctor
# reports "no gates declared" rather than failing. Declare one by hand: a
# function named ai_harness_gate_<name> plus AI_HARNESS_GATE_TOOLS_<name>,
# then add <name> to AI_HARNESS_GATES below. See README.md's Configuration
# section.
EOF
fi

# ------------------------------------------------------------------- config

_project=$(basename -- "$AI_HARNESS_REPO")
[ -n "$_trunk" ] || _trunk=$(git -C "$AI_HARNESS_REPO" symbolic-ref --short HEAD 2>/dev/null) ||
	die "$EX_FAIL" "init: HEAD is detached — pass --trunk <name>"

{
	printf 'AI_HARNESS_GATES="%s"\n' "${_gates# }"
	printf 'AI_HARNESS_QUICK_GATES="%s"\n\n' "$_quick"
	cat "$_gates_file"
} >"$_gateblock"

sed -e "s|@PROJECT@|$_project|g" -e "s|@TRUNK@|$_trunk|g" \
	-e "s|@WORKTREE_ROOT@|../$_project-worktrees|g" -e "s|@DETECTED@|$_detected|g" \
	"$AI_HARNESS_HOME/templates/ai-harness.conf" |
	awk -v f="$_gateblock" '
		$0 == "@GATES@" { while ((getline l < f) > 0) print l; next }
		{ print }' >"$_conf_out"

printf -- '--- .ai-harness.conf (detected from %s) ---\n' "$_detected"
cat "$_conf_out"
printf -- '--- end ---\n\n'

if [ "$_yes" = no ]; then
	[ -t 0 ] || die "$EX_USAGE" "init: refusing to write unconfirmed — pass --yes, or run from a terminal"
	printf 'Write this config to %s? [y/N] ' "$_conf"
	read -r _ans
	case $_ans in
	y | Y | yes | YES) ;;
	*) die "$EX_FAIL" "init: aborted; nothing written" ;;
	esac
fi

cp "$_conf_out" "$_conf"
printf 'init: config written to %s\n' "$_conf"

mkdir -p "$AI_HARNESS_REPO/todo"
cp "$AI_HARNESS_HOME/templates/todo-README.md" "$AI_HARNESS_REPO/todo/README.md"
printf 'init: todo/README.md written\n'

# --------------------------------------------------------------- adapters
#
# The table in adapters/README.md is the one source of which platform reads
# which dot directory. A dot directory is copied into only when it already
# exists: its presence is the only evidence the platform is in use.
# shellcheck disable=SC2016  # the backticks are markdown, matched literally
sed -n 's/^| `\([^`]*\)` *| `\([^`]*\)\/` .*/\1 \2/p' "$AI_HARNESS_HOME/adapters/README.md" |
	while read -r _platform _dir; do
		[ -d "$AI_HARNESS_HOME/adapters/$_platform" ] || continue
		if [ -d "$AI_HARNESS_REPO/$_dir" ]; then
			cp -R "$AI_HARNESS_HOME/adapters/$_platform/." "$AI_HARNESS_REPO/$_dir/"
			printf 'init: adapter %s copied into %s/\n' "$_platform" "$_dir"
		fi
	done

printf 'init: done — aih doctor\n'
