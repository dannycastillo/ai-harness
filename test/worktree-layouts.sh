#!/bin/sh
# worktree-layouts — claim, submit and a green merge from a trunk worktree in
# each supported layout (README, Worktree layouts). Prints one line per
# layout; exit 1 if any failed. A test, not a gate: it needs the conf's gates
# runnable and clones this checkout.

set -u

HOME_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
AIH=${AI_HARNESS_HOME:-$HOME_DIR}/bin/aih
S=$(CDPATH='' cd -- "$(mktemp -d)" && pwd -P)
trap 'rm -rf "$S"' EXIT
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
SRC=$S/src
git clone -q "$HOME_DIR" "$SRC" || exit 1

# layout <name> <root> <repo-dir> <trunk-dir> <bare|plain> [repair]
layout() {
	_name=$1 _root=$2 _repo=$3 _trunk=$4 _kind=$5 _repair=${6:-}
	mkdir -p "$S/$_name"
	if [ "$_kind" = bare ]; then
		git clone -q --bare "$SRC" "$S/$_name/.bare" &&
			git --git-dir="$S/$_name/.bare" worktree add -q -b t-trunk "$_trunk" HEAD || return 1
	else
		git clone -q "$SRC" "$_repo" && git -C "$_repo" checkout -q -b elsewhere &&
			git -C "$_repo" worktree add -q -b t-trunk "$_trunk" || return 1
	fi
	cd "$_trunk" || return 1
	sed -e 's/^AI_HARNESS_PROJECT=.*/AI_HARNESS_PROJECT="t"/' \
		-e 's/^AI_HARNESS_TRUNK=.*/AI_HARNESS_TRUNK="t-trunk"/' \
		-e "s#^AI_HARNESS_WORKTREE_ROOT=.*#AI_HARNESS_WORKTREE_ROOT=\"$_root\"#" \
		-e 's/^AI_HARNESS_PUSH_TRUNK=.*/AI_HARNESS_PUSH_TRUNK="no"/' \
		.ai-harness.conf >conf.new && mv conf.new .ai-harness.conf
	mkdir -p todo
	printf '# feat: t\n\n- **Priority:** low\n- **Touches:** NEW t/*\n- **Blocked by:** —\n\n## Goal\nA file.\n\n## Why\nTest.\n\n## Notes\nNone.\n\n## Done when\n- [ ] the file exists\n' >todo/feat-t.md
	git add -A && git commit -q -m 'chore: scratch trunk' || return 1
	[ -z "$_repair" ] || "$AIH" doctor --repair >&2 || return 1
	_wt=$("$AIH" claim feat-t) || return 1
	(
		cd "$_wt" || exit 1
		mkdir t && echo x >t/f && git rm -q todo/feat-t.md &&
			git add -A && git commit -q -m 'feat: add t' &&
			"$AIH" submit
	) >&2 || return 1
	"$AIH" integrate --next >&2
	[ $? -eq 10 ] || return 1
	"$AIH" integrate --continue --verdict pass >&2 || return 1
	[ -f t/f ]
}

_fail=0
run() {
	if (layout "$@") >"$S/out.$1" 2>&1; then
		printf 'ok    %s\n' "$1"
	else
		printf 'FAIL  %s\n' "$1"
		sed -n '1,40p' "$S/out.$1" | sed 's/^/      /'
		_fail=1
	fi
}

run clone-linked ../wt "$S/clone-linked/main" "$S/clone-linked/trunk" plain
run bare-sibling ../wt "" "$S/bare-sibling/trunk" bare
run bare-inside worktrees "" "$S/bare-inside/worktrees/trunk" bare repair
exit "$_fail"
