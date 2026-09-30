#!/bin/sh
# first-run — what a first-time user sees: aih init's two trunks, and where aih
# will and will not run afterwards (README, Quickstart). Prints one line per
# scenario; exit 1 if any failed. A test, not a gate: it builds scratch repos
# and clones this checkout.

set -u

HOME_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
AIH=${AI_HARNESS_HOME:-$HOME_DIR}/bin/aih
S=$(CDPATH='' cd -- "$(mktemp -d)" && pwd -P)
trap 'rm -rf "$S"' EXIT
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
DATE=$(date -u +%Y%m%d)
TRUNK=ai-harness-$DATE

scratch() { # <dir>
	mkdir -p "$1" && git -C "$1" init -q -b main && echo x >"$1/f" &&
		git -C "$1" add f && git -C "$1" commit -q -m 'chore: first'
}

# says <dir> <text> <aih args...>: aih fails from <dir> and prints <text>
says() {
	_d=$1 _want=$2
	shift 2
	_out=$(cd "$_d" && "$AIH" "$@" 2>&1)
	[ $? -ne 0 ] || { echo "expected failure from $_d: $*" && return 1; }
	case $_out in
	*"$_want"*) return 0 ;;
	esac
	printf 'from %s, wanted:\n  %s\ngot:\n  %s\n' "$_d" "$_want" "$_out"
	return 1
}

runs() { # <dir> <aih args...>
	_d=$1
	shift
	(cd "$_d" && "$AIH" "$@" >/dev/null 2>&1) || { echo "aih $* failed in $_d" && return 1; }
}

dated_trunk() {
	P=$S/a/proj
	W=$S/a/proj-worktrees/$TRUNK
	scratch "$P" || return 1
	_before=$(git -C "$P" rev-parse main)
	(cd "$P" && "$AIH" init --yes) >/dev/null 2>&1 || { echo "init failed" && return 1; }
	git -C "$P" show-ref -q --verify "refs/heads/$TRUNK" || { echo "no branch $TRUNK" && return 1; }
	[ -f "$W/.ai-harness.conf" ] || { echo "no config in $W" && return 1; }
	[ "$(git -C "$W" log -1 --format=%s)" = 'chore: add ai-harness' ] || { echo "wrong commit" && return 1; }
	[ -z "$(git -C "$W" status --porcelain)" ] || { echo "trunk tree is dirty" && return 1; }
	[ "$(git -C "$P" rev-parse main)" = "$_before" ] || { echo "main moved" && return 1; }
	[ -z "$(git -C "$P" status --porcelain)" ] && [ ! -e "$P/.ai-harness.conf" ] || { echo "main tree touched" && return 1; }
	runs "$W" doctor || return 1

	# before the merge, main has no config
	says "$P" "this branch (main) does not have an active aih trunk." status || return 1
	says "$P" "cd $W && aih status" status || return 1
	git -C "$P" worktree add -q --detach "$S/a/scratch" main || return 1
	says "$S/a/scratch" "this branch ($(git -C "$S/a/scratch" rev-parse --short HEAD)) does not have an active aih trunk." status || return 1
	says "$S/a/scratch" "cd $W && aih status" status || return 1

	mkdir -p "$W/todo"
	printf '# feat: t\n\n- **Priority:** low\n- **Touches:** NEW t/*\n- **Blocked by:** —\n\n## Goal\nA file.\n\n## Why\nTest.\n\n## Notes\nNone.\n\n## Done when\n- [ ] the file exists\n' >"$W/todo/feat-t.md"
	git -C "$W" add -A && git -C "$W" commit -q -m 'chore: a todo' || return 1
	C=$(cd "$W" && "$AIH" claim feat-t) || { echo "claim failed" && return 1; }
	runs "$C" status || return 1
	runs "$W" status || return 1
	says "$C" "run it from the $TRUNK checkout: cd $W && aih run" run --all || return 1
	says "$C" "run it from the $TRUNK checkout: cd $W && aih integrate" integrate --next || return 1
	_pending=$P/.git/ai-harness/integrate/pending
	mkdir -p "$(dirname -- "$_pending")" && printf 'phase=judge\nstem=feat-t\n' >"$_pending" || return 1
	says "$C" "run it from the $TRUNK checkout: cd $W && aih dispatch reviewer" dispatch reviewer || return 1

	# after the merge, main holds the config and names the trunk
	git -C "$P" merge -q --no-ff -m 'Merge trunk' "$TRUNK" || return 1
	git -C "$S/a/scratch" checkout -q --detach main || return 1
	says "$P" "run this from the $TRUNK checkout: cd $W" status || return 1
	says "$S/a/scratch" "run this from the $TRUNK checkout: cd $W" status || return 1
	runs "$C" status || return 1
	runs "$W" status || return 1

	git -C "$P" worktree remove --force "$W" || return 1
	says "$P" "No active aih trunk on this machine; run aih init" status || return 1
	says "$S/a/scratch" "No active aih trunk on this machine; run aih init" status || return 1
	says "$C" "No active aih trunk on this machine; run aih init" run --all || return 1
	says "$C" "No active aih trunk on this machine; run aih init" integrate --next || return 1
	says "$C" "No active aih trunk on this machine; run aih init" dispatch reviewer || return 1
	runs "$C" status
}

# main's conf names a trunk that was retired; the trunks that are open are
# listed instead
stale_conf() {
	P=$S/f/proj
	scratch "$P" || return 1
	(cd "$P" && "$AIH" init --trunk main --yes) >/dev/null 2>&1 || { echo "init failed" && return 1; }
	git -C "$P" add -A && git -C "$P" commit -q -m 'chore: add ai-harness' || return 1
	sed -i.bak 's/^AI_HARNESS_TRUNK=.*/AI_HARNESS_TRUNK="gone"/' "$P/.ai-harness.conf" && rm "$P/.ai-harness.conf.bak"
	git -C "$P" commit -qam 'chore: name a retired trunk' || return 1
	says "$P" "No active aih trunk on this machine; run aih init" status || return 1

	(cd "$P" && "$AIH" init --new-trunk t-one --yes) >/dev/null 2>&1 || { echo "init failed" && return 1; }
	W1=$S/f/proj-worktrees/t-one
	[ -d "$W1" ] || W1=$S/f/ai-harness-worktrees/t-one
	_out=$(cd "$P" && "$AIH" status 2>&1)
	[ $? -ne 0 ] || { echo "status succeeded on stale conf" && return 1; }
	case $_out in
	*"this branch (main) does not have an active aih trunk."*"Active aih trunk found at $W1:"*"cd $W1 && aih status"*) ;;
	*) printf 'one trunk, got:\n  %s\n' "$_out" && return 1 ;;
	esac

	(cd "$P" && "$AIH" init --new-trunk t-two --yes) >/dev/null 2>&1 || { echo "init failed" && return 1; }
	W2=$(dirname -- "$W1")/t-two
	_out=$(cd "$P" && "$AIH" status 2>&1)
	case $_out in
	*"Active aih trunks found:"*"t-one: cd $W1 && aih status"*"t-two: cd $W2 && aih status"*) ;;
	*) printf 'two trunks, got:\n  %s\n' "$_out" && return 1 ;;
	esac
}

trunk_here() {
	P=$S/b/proj
	scratch "$P" || return 1
	_before=$(git -C "$P" rev-parse HEAD)
	(cd "$P" && "$AIH" init --trunk main --yes) >/dev/null 2>&1 || { echo "init failed" && return 1; }
	[ -f "$P/.ai-harness.conf" ] || { echo "no config here" && return 1; }
	[ "$(git -C "$P" rev-parse HEAD)" = "$_before" ] || { echo "init committed" && return 1; }
	[ "$(git -C "$P" branch --list | wc -l)" -eq 1 ] && [ "$(git -C "$P" worktree list | wc -l)" -eq 1 ] ||
		{ echo "init made a branch or worktree" && return 1; }
	git -C "$P" add -A && git -C "$P" commit -q -m 'chore: add ai-harness' || return 1
	runs "$P" doctor || return 1
	runs "$P" status || return 1
	git -C "$P" worktree add -q --detach "$S/b/scratch" || return 1
	says "$S/b/scratch" "run this from the main checkout: cd $P" status
}

next_trunk() {
	P=$S/c/proj
	git clone -q "$HOME_DIR" "$P" || return 1
	(cd "$P" && "$AIH" init --new-trunk t-next --yes) >/dev/null 2>&1 || { echo "init failed" && return 1; }
	W=$S/c/ai-harness-worktrees/t-next
	[ -f "$W/.ai-harness.conf" ] || { echo "no config in $W" && return 1; }
	_d=$(diff "$P/.ai-harness.conf" "$W/.ai-harness.conf" | grep -c '^[<>]')
	[ "$_d" -eq 2 ] || { echo "config differs in $_d lines, not 2" && return 1; }
	diff "$P/.ai-harness.conf" "$W/.ai-harness.conf" | grep -q "^> AI_HARNESS_TRUNK=\"t-next\"" ||
		{ echo "the difference is not AI_HARNESS_TRUNK" && return 1; }
	[ "$(git -C "$W" log -1 --format=%s)" = 'chore: open trunk t-next' ] || { echo "wrong commit" && return 1; }

	(cd "$W" && "$AIH" init --new-trunk second --yes) >/dev/null 2>&1 || { echo "second init failed" && return 1; }
	W2=$S/c/ai-harness-worktrees/second
	[ "$(git -C "$W2" log -1 --format=%s)" = 'chore: open trunk second' ] || { echo "wrong second commit" && return 1; }
	_files=$(git -C "$W2" show --format= --name-only HEAD)
	[ "$_files" = .ai-harness.conf ] || { echo "second commit touches: $_files" && return 1; }
}

push_new_trunk() {
	P=$S/d/proj
	scratch "$P" || return 1
	git init -q --bare "$S/d/remote.git" || return 1
	git -C "$P" remote add origin "$S/d/remote.git" &&
		git -C "$P" push -q -u origin main || return 1
	(cd "$P" && "$AIH" init --trunk main --yes) >/dev/null 2>&1 || { echo "init failed" && return 1; }
	sed -i.bak 's/^AI_HARNESS_PUSH_TRUNK=.*/AI_HARNESS_PUSH_TRUNK="yes"/' "$P/.ai-harness.conf" && rm "$P/.ai-harness.conf.bak"
	git -C "$P" add -A && git -C "$P" commit -q -m 'chore: add ai-harness' || return 1
	_out=$(cd "$P" && "$AIH" init --new-trunk t --yes 2>&1) || { echo "init failed: $_out" && return 1; }
	case $_out in *"init: pushed t to origin with -u"*) ;; *) echo "did not say it pushed: $_out" && return 1 ;; esac
	[ "$(git -C "$P" rev-parse --abbrev-ref t@{upstream})" = origin/t ] || { echo "t has no upstream" && return 1; }
	git -C "$S/d/remote.git" rev-parse -q --verify refs/heads/t >/dev/null || { echo "remote lacks t" && return 1; }

	git -C "$P" branch -q --unset-upstream t
	_out=$(cd "$S/d/ai-harness-worktrees/t" 2>/dev/null || cd "$S/d/proj-worktrees/t" && "$AIH" doctor 2>&1)
	case $_out in *"no upstream — integrate cannot push"*) ;; *) echo "doctor silent: $_out" && return 1 ;; esac
}

push_no_remote() {
	P=$S/e/proj
	scratch "$P" || return 1
	(cd "$P" && "$AIH" init --trunk main --yes) >/dev/null 2>&1 || { echo "init failed" && return 1; }
	sed -i.bak 's/^AI_HARNESS_PUSH_TRUNK=.*/AI_HARNESS_PUSH_TRUNK="yes"/' "$P/.ai-harness.conf" && rm "$P/.ai-harness.conf.bak"
	git -C "$P" add -A && git -C "$P" commit -q -m 'chore: add ai-harness' || return 1
	_out=$(cd "$P" && "$AIH" init --new-trunk t --yes 2>&1) || { echo "init failed: $_out" && return 1; }
	case $_out in *"init: not pushed"*"no remote"*) ;; *) echo "did not say why: $_out" && return 1 ;; esac
	[ "$(git -C "$P/../proj-worktrees/t" log -1 --format=%s)" = 'chore: open trunk t' ] || { echo "not committed" && return 1; }
}

_fail=0
run() {
	if ("$1") >"$S/out.$1" 2>&1; then
		printf 'ok    %s\n' "$1"
	else
		printf 'FAIL  %s\n' "$1"
		sed -n '1,40p' "$S/out.$1" | sed 's/^/      /'
		_fail=1
	fi
}

run dated_trunk
run trunk_here
run next_trunk
run stale_conf
run push_new_trunk
run push_no_remote
exit "$_fail"
