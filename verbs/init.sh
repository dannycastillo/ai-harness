# init — configure a repo the harness has never seen
#
# usage: aih init [--yes] [--force] [--trunk <name>] [--new-trunk [<name>]]
#
# Detects the stack (go.mod, package.json, Cargo.toml, pyproject.toml,
# Makefile, in that order), prints the .ai-harness.conf it would write, and
# stops for a y unless given --yes or run from a terminal. Writes the config,
# todo/README.md, and the adapters whose dot directory already exists.
# Never copies the tree or edits AGENTS.md. The trunk is either a new branch in its own worktree, ai-harness-YYYYMMDD,
# where init commits what it wrote (the default), or the branch checked out
# here (--trunk), where it commits nothing and refuses to overwrite an
# existing .ai-harness.conf without --force.
#
# Runs: in any git repository, with or without a config.

# One install per machine: the tree is never copied into the repo, and the
# protocol reaches agents through aih protocol and aih role, not through
# AGENTS.md (adr-2026-09-26-one-install-per-machine,
# adr-2026-09-26-the-protocol-ships-with-the-tree).

_yes=no
_force=no
_trunk=
_newname=
_mode=
while [ $# -gt 0 ]; do
	case $1 in
	--yes | -y) _yes=yes ;;
	--force) _force=yes ;;
	--trunk)
		[ "$_mode" != new ] || die "$EX_USAGE" "init: --trunk and --new-trunk are exclusive"
		[ $# -gt 1 ] || die "$EX_USAGE" "init: --trunk needs a name"
		_trunk=$2 && _mode=here && shift
		;;
	--new-trunk)
		[ "$_mode" != here ] || die "$EX_USAGE" "init: --trunk and --new-trunk are exclusive"
		_mode=new
		case ${2:-} in
		'' | -*) ;;
		*) _newname=$2 && shift ;;
		esac
		;;
	*) die "$EX_USAGE" "usage: aih init [--yes] [--force] [--trunk <name>] [--new-trunk [<name>]]" ;;
	esac
	shift
done

_project=$(basename -- "$(ai_harness_main_worktree)")
_here=$(git symbolic-ref --short HEAD 2>/dev/null) || _here=

if [ -z "$_mode" ]; then
	if [ "$_yes" = yes ]; then
		_mode=new
	else
		[ -t 0 ] || die "$EX_USAGE" "init: refusing to write unconfirmed — pass --yes, or run from a terminal"
		printf 'Trunk: where ai-harness merges finished work\n'
		printf '  1) new branch and worktree %s  (recommended)\n' "ai-harness-$(date -u +%Y%m%d)"
		[ -z "$_here" ] || printf '  2) the branch checked out here (%s)\n' "$_here"
		printf 'Choice [1]: '
		read -r _ans
		case $_ans in
		1 | '') _mode=new ;;
		2) [ -n "$_here" ] || die "$EX_USAGE" "init: HEAD is detached — pass --trunk <name>"
			_mode=here ;;
		*) die "$EX_USAGE" "init: choose 1 or 2" ;;
		esac
		printf '\n'
	fi
fi

_src_conf="$AI_HARNESS_REPO/.ai-harness.conf"
_dest=$AI_HARNESS_REPO
_copy=no
if [ "$_mode" = new ]; then
	[ -n "$_newname" ] || _newname="ai-harness-$(date -u +%Y%m%d)"
	git check-ref-format --branch "$_newname" >/dev/null 2>&1 ||
		die "$EX_USAGE" "init: not a branch name: $_newname"
	! git show-ref -q --verify "refs/heads/$_newname" ||
		die "$EX_FAIL" "init: branch $_newname already exists"
	_trunk=$_newname
	AI_HARNESS_WORKTREE_ROOT=
	[ ! -f "$_src_conf" ] || {
		_copy=yes
		AI_HARNESS_WORKTREE_ROOT=$(sed -n 's/^AI_HARNESS_WORKTREE_ROOT="\(.*\)"$/\1/p' "$_src_conf" | head -1)
	}
	[ -n "$AI_HARNESS_WORKTREE_ROOT" ] || AI_HARNESS_WORKTREE_ROOT="../$_project-worktrees"
	_wroot=$(ai_harness_worktree_root) ||
		die "$EX_FAIL" "init: the worktree root's parent does not exist: $_wroot"
	_dest="$_wroot/$_newname"
	[ ! -e "$_dest" ] || die "$EX_FAIL" "init: $_dest already exists"
else
	[ ! -f "$_src_conf" ] || [ "$_force" = yes ] ||
		die "$EX_FAIL" "init: $_src_conf already exists — use --force to overwrite"
fi
_conf="$_dest/.ai-harness.conf"

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
	_gate build go 'go build -o /dev/null ./...'
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

[ -n "$_trunk" ] || _trunk=$_here
[ -n "$_trunk" ] || die "$EX_FAIL" "init: HEAD is detached — pass --trunk <name>"

_push_trunk=no
git -C "$AI_HARNESS_REPO" rev-parse -q --verify --abbrev-ref "$_trunk@{upstream}" >/dev/null 2>&1 &&
	_push_trunk=yes

{
	printf 'AI_HARNESS_GATES="%s"\n' "${_gates# }"
	printf 'AI_HARNESS_QUICK_GATES="%s"\n\n' "$_quick"
	cat "$_gates_file"
} >"$_gateblock"

if [ "$_copy" = yes ]; then
	sed "s|^AI_HARNESS_TRUNK=.*|AI_HARNESS_TRUNK=\"$_trunk\"|" "$_src_conf" >"$_conf_out"
	_detected="the config here, with only AI_HARNESS_TRUNK changed"
else
	sed -e "s|@PROJECT@|$_project|g" -e "s|@TRUNK@|$_trunk|g" \
		-e "s|@WORKTREE_ROOT@|../$_project-worktrees|g" -e "s|@DETECTED@|$_detected|g" \
		-e "s|@PUSH_TRUNK@|$_push_trunk|g" \
		"$AI_HARNESS_HOME/templates/ai-harness.conf" |
		awk -v f="$_gateblock" '
			$0 == "@GATES@" { while ((getline l < f) > 0) print l; next }
			{ print }' >"$_conf_out"
fi

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

if [ "$_mode" = new ]; then
	git worktree add -q -b "$_trunk" "$_dest" HEAD
fi

cp "$_conf_out" "$_conf"
printf 'init: config written to %s\n' "$_conf"

mkdir -p "$_dest/todo/new"
cp "$AI_HARNESS_HOME/templates/todo-README.md" "$_dest/todo/README.md"
: >"$_dest/todo/new/.keep"
printf 'init: todo/README.md and todo/new/.keep written\n'

# --------------------------------------------------------------- adapters
#
# The table in adapters/README.md is the one source of which platform reads
# which dot directory. A dot directory is copied into only when it already
# exists: its presence is the only evidence the platform is in use.
# shellcheck disable=SC2016  # the backticks are markdown, matched literally
sed -n 's/^| `\([^`]*\)` *| `\([^`]*\)\/` .*/\1 \2/p' "$AI_HARNESS_HOME/adapters/README.md" |
	while read -r _platform _dir; do
		[ -d "$AI_HARNESS_HOME/adapters/$_platform" ] || continue
		if [ -d "$_dest/$_dir" ]; then
			cp -R "$AI_HARNESS_HOME/adapters/$_platform/." "$_dest/$_dir/"
			printf 'init: adapter %s copied into %s/\n' "$_platform" "$_dir"
		fi
	done

if [ "$_mode" = new ]; then
	git -C "$_dest" add -A
	_subject='chore: add ai-harness'
	[ "$_copy" = no ] || _subject="chore: open trunk $_trunk"
	git -C "$_dest" commit -q -m "$_subject"
	printf 'init: committed on %s as "%s"\n' "$_trunk" "$_subject"
	if [ "$(sed -n 's/^AI_HARNESS_PUSH_TRUNK="\(.*\)"$/\1/p' "$_conf" | head -1)" = yes ]; then
		_remote=$(git config "branch.${_here:-main}.remote" 2>/dev/null || git config branch.main.remote 2>/dev/null) || _remote=
		[ -n "$_remote" ] || ! git remote | grep -qx origin || _remote=origin
		if [ -z "$_remote" ]; then
			printf 'init: not pushed — AI_HARNESS_PUSH_TRUNK is yes but this repo has no remote\n'
		elif git -C "$_dest" push -q -u "$_remote" "$_trunk" 2>/dev/null; then
			printf 'init: pushed %s to %s with -u\n' "$_trunk" "$_remote"
		else
			warn "init: push of $_trunk to $_remote was rejected — it stays local; push it once with -u"
		fi
	fi
	printf 'init: done — trunk %s is at %s\n\n  cd %s\n  aih doctor\n' "$_trunk" "$_dest" "$_dest"
else
	printf 'init: done — commit these on %s, then aih doctor\n' "$_trunk"
fi
