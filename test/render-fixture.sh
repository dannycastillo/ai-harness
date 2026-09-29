#!/bin/sh
# render-fixture — a throwaway repo in every state status and plan can show,
# rendered by both. Run it before and after a rendering change and diff the
# two outputs for wording. Pids and ages vary; normalize them first:
#
#   sh test/render-fixture.sh | sed -E 's/pid [0-9]+/pid N/g' > after.txt
#
# The exit status says whether any verb crashed: every section, D included,
# expects plan and status to exit 0. A nonzero exit prints rc=N where it
# happened, is counted, and the last line is "crashes: N" (naming the
# sections when N is not 0); the script exits 1 unless N is 0.

set -eu

AIH=${AIH:-$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)/bin/aih}
# pwd -P: on macOS mktemp answers under /var, a symlink, and the harness
# prints paths relative to the resolved worktree.
S=$(CDPATH='' cd -- "$(mktemp -d)" && pwd -P)
SP=
trap 'if [ -n "$SP" ]; then kill "$SP" 2>/dev/null; wait "$SP" 2>/dev/null || :; fi; rm -rf "$S"' EXIT

mkdir -p "$S/fx" && cd "$S/fx" && git init -q -b main . && git config user.email fx@fx && git config user.name fx
cat > .ai-harness.conf <<'EOF'
AI_HARNESS_PROJECT=fx
AI_HARNESS_TRUNK=main
AI_HARNESS_WORKTREE_ROOT=../fx-wt
AI_HARNESS_PREFIXES="feat fix doc chore"
AI_HARNESS_MAX_WORKERS=3
AI_HARNESS_GATES=""
AI_HARNESS_QUICK_GATES=""
EOF
mkdir todo lib
mk() { printf '# %s\n\n- **Priority:** %s\n- **Touches:** %s\n- **Blocked by:** %s\n\n## Done when\n- [ ] x\n' "$1" "$2" "$3" "$4" > "todo/$1.md"; }
mk fix-a high lib/a.sh -; mk fix-b high lib/b.sh -; mk feat-c medium lib/c.sh -; mk feat-pane-resize medium lib/agents.sh -
mk chore-drop-old-adapter low 'adapters/*' -; mk fix-empty-desc-line medium lib/render.sh -; mk feat-status-rewrite low lib/status.sh fix-empty-desc-line
mk fix-parked-one high lib/p.sh -
touch lib/a.sh; git add -A; git commit -qm 'chore: fixture'

D=.git/ai-harness
mkdir -p $D/claims $D/agents $D/submitted $D/parked $D/integrate $D/run $D/lock/integrate $D/log
printf 'fix-a\nfix-b\nfeat-c\nfeat-pane-resize\nfix-parked-one\n' > $D/run/set
claim() { printf 'todo=todo/%s.md\nbranch=%s\nworktree=%s\ntouches=%s\nagent=loop\nclaimed=x\nbase=x\n' "$1" "$2" "$PWD/../fx-wt/$1" "$3" > "$D/claims/$1"; mkdir -p "../fx-wt/$1"; }
claim fix-a fix/a lib/a.sh; claim fix-b fix/b lib/b.sh; claim feat-c feat/c lib/c.sh; claim fix-parked-one fix/parked-one lib/p.sh
NOW=$(date -u +%s)
sleep 600 & SP=$!
# fix-a: submitted, judgment pending, reviewer lost
printf 'role=reviewer\nstem=fix-a\npid=99999\ncmd=x\ncwd=x\nstarted=x\nepoch=%s\nlog=%s/%s/log/fix-a.reviewer.log\nexit=137\nended=x\n' $((NOW-300)) "$PWD" "$D" > $D/agents/fix-a.reviewer; : > $D/agents/fix-a.reviewer.lost
printf 'stem=fix-a\nphase=judge\ncheck=ok\n' > $D/integrate/pending; printf 'head=abc\nepoch=1\n' > $D/submitted/fix-a
# fix-b: worker exited without submitting
printf 'role=worker\nstem=fix-b\npid=99998\ncmd=x\ncwd=x\nstarted=x\nepoch=%s\nlog=%s/%s/log/fix-b.worker.log\nexit=1\nended=x\n' $((NOW-1500)) "$PWD" "$D" > $D/agents/fix-b.worker
# feat-c: worker alive
printf 'role=worker\nstem=feat-c\npid=%s\ncmd=x\ncwd=x\nstarted=x\nepoch=%s\nlog=x\n' $SP $((NOW-420)) > $D/agents/feat-c.worker
# fix-parked-one: parked; and a stale integrate lock
printf 'code=gate-red-merge\ndetail=test: FAIL TestPane in lib/p_test.sh after the merge, trunk is red and the worktree has the failing diff\nparked=x\n' > $D/parked/fix-parked-one
printf 'pid=3310\nhost=box\nverb=integrate\nsince=2026-09-26T09:00:00Z\nepoch=%s\n' $((NOW-4000)) > $D/lock/integrate/holder
cat > $D/events <<EOF
2026-09-26T09:02:10Z @run - started fix-a fix-b feat-c feat-pane-resize fix-parked-one
2026-09-26T09:02:11Z fix-a - claimed fix/a by loop
2026-09-26T09:02:11Z fix-a worker dispatched pid 1
2026-09-26T09:02:12Z fix-b - claimed fix/b by loop
2026-09-26T09:02:12Z fix-b worker dispatched pid 2
2026-09-26T09:02:12Z fix-parked-one - claimed fix/parked-one by loop
2026-09-26T09:20:00Z fix-b worker exited 1
2026-09-26T09:30:00Z fix-a worker submitted abc1234
2026-09-26T09:31:00Z fix-parked-one - parked gate-red-merge: test: FAIL TestPane
2026-09-26T09:32:00Z feat-c - claimed feat/c by loop
2026-09-26T09:32:00Z feat-c worker dispatched pid $SP
2026-09-26T09:40:00Z fix-a reviewer dispatched pid 99999
2026-09-26T09:43:00Z fix-a reviewer exited 137
2026-09-26T09:43:01Z fix-a reviewer lost exited 137 with the judgment pending
2026-09-26T09:43:55Z @run - stopped reviewer-lost fix-a: aih dispatch reviewer --detach, or integrate --continue --park
EOF

CRASHES=0 BAD=
crash() { echo "rc=$1"; CRASHES=$((CRASHES + 1)); BAD="$BAD $2"; }
both() {
  "$AIH" plan || crash $? "$1 plan"
  echo "--- status"
  "$AIH" status || crash $? "$1 status"
}
echo "=== A: stopped run, named set"; both A
echo; echo "=== B: live loop, named set"
grep -v '@run - stopped' $D/events > $D/e && mv $D/e $D/events
mkdir -p $D/lock/run; printf 'pid=%s\nhost=box\nverb=run\nsince=x\nepoch=%s\n' $SP $((NOW-2500)) > $D/lock/run/holder; both B
echo; echo "=== C: live loop, every todo"; : > $D/run/set; both C
echo; echo "=== D: explicit stems during a live loop"; "$AIH" plan fix-empty-desc-line feat-status-rewrite || crash $? "D plan"
echo; echo "=== E: dead loop lock, paused, every worker slot taken"
printf 'pid=99997\nhost=box\nverb=run\nsince=x\nepoch=1\n' > $D/lock/run/holder; echo "trunk needs a look" > $D/PAUSED; both E
echo; echo "=== F: no run, an invalid todo, a barrier"
rm -rf $D/lock $D/PAUSED
printf '# feat: bad\n\n- **Priority:** urgent\n- **Touches:** lib/x.sh\n' > todo/feat-bad-priority.md
printf '# doc: license\n\n- **Priority:** high\n- **Touches:** ALL\n' > todo/doc-add-license.md; both F
echo; echo "=== G: empty backlog"; rm -rf $D/claims $D/agents $D/submitted $D/parked $D/integrate todo/*.md; both G
echo "crashes: $CRASHES${BAD:+ (${BAD# })}"
[ "$CRASHES" -eq 0 ] || exit 1
