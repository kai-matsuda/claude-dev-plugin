#!/usr/bin/env bash
# Reference lint for skill-facing docs (INFRA-26): named commands exist, stale phrases are absent.
# Not the test seam for any skill; that is a subagent following the skill against the fixture.
# One section per doc (INFRA-27 added 3-6):
#   1. the /implement-spec driver text (chezmoi-0jp.24): no ticket-level procedure, names the
#      refusals, the spawn with its pointer at the waiting rule (chezmoi-p4q) and the end states,
#      the story-closure human stop and the add-mode stall hint pinned (chezmoi-9v4.1.6);
#   2. the human runbook docs/WORKFLOW.md (chezmoi-0jp.25) and the /workflow skill:
#      names only commands that exist, no stale cross-repo wording, the cut skills' argument
#      written in the runbook and filled in on /workflow's next lines (chezmoi-nz0);
#   3. /spec-to-stories: user-typed, the required argument with its usage line and no
#      no-argument epic recovery (chezmoi-nz0), the refusals, preflight, the orientation written
#      to the story bead's design field behind its header line, no file and no git write in any
#      owner repo (chezmoi-cdf, ADR 0010), no Jira comment; the story DAG detected per edge,
#      a split proposed only for a deprecate-then-remove and the user's split for any reason,
#      the cycle refusal before any bead exists, the topological order with one Blocked by
#      line per edge in both forms, and every edge and publish in the orientation and the end
#      report (ADR 0011); the frontmatter's one story per PR, the deprecate-then-remove
#      split's full shape, a story with an edge on a skipped story skipped too and reported
#      only (the epic bead note is for a no-database skip), the cycle refusal ahead of step
#      7's epic bead, the deploy as the
#      earlier story's last step, a quiz cycle rejected without ending the skill, and the
#      tracker doc's out-of-scope cases (git tag or ssh URL, several crates in one story);
#      add mode on a feature whose stories exist (the refusal only when every story is
#      closed, never the unconditional "stories exist"), its story states, its additions
#      answering failed twice: notes, one sandbox-disabled forge query per finished story it
#      touches with the MERGED, OPEN and no-forge paths, and its additions-only publish
#      with the dependent's body rewritten and Jira untouched (chezmoi-9v4.1.7);
#   4. the /spec-to-tickets driver: user-typed, the same argument rule as 3, the refusals,
#      cutters pointed at the waiting rule and without a model override, explicit dependent
#      lines, the closed and publish-failed lines, a Jira comment over every story, no
#      story-cut procedure; the cycle refusal, topological waves with every upstream
#      breakdown in a dependent's brief, the inline re-cut of an already cut dependent keyed on
#      its missing bump, a finished dependent excluded at step 1, a skipped repo's publish line
#      as an edge with no dependency, the held-back cascade narrowed to a dependency without
#      its publish ticket, and no two-wave cap (ADR 0011);
#   (3, 4 and 1 point at the shared preflight and epic gather that section 6 checks; 3, 4 and 7
#   cite the "epic bead writes" convention that section 6 checks)
#   5. the agent docs and every file under the skills dir: no retired "cut one", "cut two" or
#      <spec-slug>, as whole words, and no story-cut.md (the notes moved to the story bead's
#      design field, chezmoi-cdf); and across those, the project CLAUDE.md and the runbook:
#      none of the retired walk-up phrases ("nearest ancestor", "walking up", "walk up",
#      "one level up", "the home repo included", "the workspace root included",
#      "no repos.yaml above", "workspace inbox", "workspace's inbox", the "home repo <home repo>"
#      Parent form), and no "run_in_background: false" in any skill or agent doc, since no
#      foreground spawn exists (chezmoi-p4q).
#      That one list is the only walk-up check; sections 2-4 and 7 do not repeat it; the same
#      four file kinds also lack the retired story-DAG wording ("one story per repo", feat/<key>-<n>,
#      "chains are out of scope", "only text blocker", "two waves suffice"; ADR 0011);
#   6. the shared rules: orchestration.md's working-directory preflight, its waiting rule
#      (an Agent call returns at once, the orchestrator ends its turn and the completion
#      notification resumes it, never a Bash poll loop; pgrep is dead in the sandbox) with its
#      idle rule (Bash in the foreground only below the driver, chezmoi-p4q) and the
#      merger's lock wait as its one shell wait (chezmoi-sn1), the
#      Orchestrator role's beads-only principle for the epic-level stages (ADR 0010), the
#      Frontier's unclaim rule (chezmoi-jvc) and its ready-for-agent-only admission with the
#      finished story that tolerates an untriaged child (chezmoi-wgi), the Review verdict rule
#      with its verdict lines, its blocking-or-minor tags and its blocking-rounds-only count
#      (chezmoi-49k), issue-tracker.md's
#      one test of the session mode in its opening (ADR 0008), its epic bead gather with its
#      refusals, its spec fetch with the Spec: fallback, its "epic bead writes" convention,
#      and its close rule counting a story's children as the finished story does (chezmoi-afn);
#   7. /story-to-tickets: the spec fetch pointer, the story cutter and publish triggers, the
#      design field read, the one test and "home <home name>" in the template's Parent line,
#      the pair read per edge (one bump per publish blocker, Dependency:/Dependent: lines),
#      the two refusals (two publish tickets; a finished story pointing at add mode) and the
#      re-cut's added bump, re-edge and citation of the per-edge rules (ADR 0011);
#   8. /implement-story: the deliver step pushes and opens the PR on the typed command's
#      authority (orchestration.md's delivery rule, checked in 6; ADR 0009), a refused push
#      is a failed: line, so no step waits on the user, the Gitignore step commits a dirty
#      .gitignore made of the rule's entries alone while an edit of the user's in it is a
#      failed: line (chezmoi-hkn), its exploration subagent reads the story's design field
#      and owns .spec-notes/<epic-id>/ (chezmoi-cdf), and a ticket whose runner failed is
#      unclaimed before the next frontier read, with the resume pointer noted on a second
#      failure and step 9's resume: line naming when a human runs the unclaim (chezmoi-jvc;
#      the Frontier's unclaim rule is checked in 6), its frontier read keeps ready-for-agent
#      tickets only, its review step captures deferred findings in the inbox through the
#      retro capture, its finished story tolerates an untriaged child (chezmoi-wgi), and its
#      merger waits on the owner lock in one bounded until-loop, never a check-and-sleep loop
#      by hand (chezmoi-sn1), and its frontier spawn and the ticket runner brief end the turn
#      after spawning and carry the idle rule (chezmoi-p4q), and its integration branch is
#      feat/<story-id> keyed or not, a delivered story with an open agent ticket passes one
#      merge guard (MERGED, CLOSED unmerged, OPEN, ask), a story-closure wait says to merge
#      and run /close-story, and the sibling line is <repo> <story-id> <url> (chezmoi-9v4.1.5,
#      ADR 0011), and its clean-up step removes worktrees with the sandbox disabled up front,
#      sweeps every worktree-agent-* and .worktrees/ worktree whose branch is merged into the
#      integration branch, earlier runs' included, and reports a locked or unmerged one in the
#      report's worktrees: line instead of forcing it (chezmoi-73d), and its implementer,
#      fix-up implementer and merger briefs start with the TMPDIR line, whose rule section 6
#      checks in orchestration.md (chezmoi-3eg), and its reviewer brief tags every finding
#      blocking or minor and ends on the verdict line, its runner step 3 and story review step 7
#      pointing at the rules doc's Review verdict, whose rule section 6 checks (chezmoi-49k);
#   9. /close-story: its ticket check skips a child carrying needs-triage or wontfix, as the
#      finished story does, and its refusal names each open child's status and label
#      (chezmoi-afn);
#  10. the tracker and orchestration docs: both name the story DAG and the human gate ticket,
#      and neither says "only text blocker" nor puts chains out of scope; the orchestration
#      doc ends a story-closure wait as a human stop and readies a publish ticket on its
#      story's tickets; the tracker doc's story body shows no unfillable gate ticket line
#      and orders a middle story of a chain in one topological pass, creates every
#      repo-session story under the epic bead, and makes a deploy split wait on the
#      earlier story's closure (ADR 0011).
# Usage: scripts/lint-skill-docs.sh [implement-spec SKILL.md [WORKFLOW.md]]
# Each section guards on its doc existing, so the lint passes on a tree without that doc yet;
# the plugin layout is skills/, docs/agents/, docs/WORKFLOW.md and CLAUDE.md under the repo root.
# SKILLS_DIR and AGENT_DOCS override the skills and agent docs directories (scratch copies).
# USER_CLAUDE_MD overrides the project CLAUDE.md (default: CLAUDE.md under the repo root).
# PLUGIN_SKILLS overrides the plugin skills directory (default: newest installed mattpocock-skills).
set -u
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
fail=0
bad() { echo "FAIL: $*"; fail=1; }
has() { grep -qiF -- "$2" "$f" || bad "missing: $1 ($2)"; }
hasc() { grep -qF -- "$2" "$f" || bad "missing (case-sensitive): $1 ($2)"; }
hase() { grep -qE -- "$2" "$f" || bad "missing: $1 ($2)"; }
lacks() { [ -f "$f" ] || return 0; if grep -qiE -- "$2" "$f"; then bad "present: $1 ($2)"; grep -niE -- "$2" "$f" | head -3; fi; }

skills=${SKILLS_DIR:-$root/skills}
agents=${AGENT_DOCS:-$root/docs/agents}
user_claude_md=${USER_CLAUDE_MD:-$root/CLAUDE.md}
# an explicitly passed path ($1, $2) or a set override must exist; only the defaults are guarded
# by [ -f ] below
for given in "${1:-}" "${2:-}"; do
  [ -z "$given" ] || [ -f "$given" ] || bad "no such file: $given"
done
for given in "${SKILLS_DIR:-}" "${AGENT_DOCS:-}"; do
  [ -z "$given" ] || [ -d "$given" ] || bad "no such directory: $given"
done
[ -z "${USER_CLAUDE_MD:-}" ] || [ -f "$USER_CLAUDE_MD" ] || bad "no such file: $USER_CLAUDE_MD"

# ---- 1. /implement-spec driver ----
f=${1:-$skills/implement-spec/SKILL.md}
if [ -f "$f" ]; then
echo "== $f"
lacks "worktree steps" 'worktree'
# no merge steps; the one allowed use is the human stop naming "the PR to merge" for the user
# (chezmoi-9v4.1.6), so that phrase is blanked before the scan
merge_scan=$(sed 's/the PR to merge//gI' "$f")
if grep -qi 'merge' <<<"$merge_scan"; then
  bad "present: merge steps (merge)"; grep -ni 'merge' <<<"$merge_scan" | head -3
fi
has "story-closure blocker is open until closed" 'open until that story is closed'
has "story-closure human stop line" 'the PR to merge and the /close-story <story-id> to run'
has "human stop line carries the PR url" '<owner repo> <story-id> <pr url>'
has "human stop trigger covers story closures" 'held only by blockers naming finished stories not yet closed'
has "chain of story closures counts toward the human stop" 'itself waits only on story closures'
has "add-mode hint keyed on the failed twice: note" 'carries a `failed twice:` note'
has "add-mode stall hint" '/spec-to-stories <KEY>-<n>'
has "add-mode stall hint without an external ref" '/spec-to-stories <epic-id>'
has "final report waiting: names a finished story" 'a finished story not yet closed'
hasc "report template shows the story-closure human: line" 'human:   <owner repo> <story-id> <pr url>'
# the glossary avoids "human ticket" for the human gate ticket ("ready-for-human ticket" is fine)
lacks "glossary's avoided term human ticket" '(^|[^-])human ticket'
lacks "review steps" 'review'
lacks "PR steps" 'gh pr|tea pr|draft PR|mark ready'
has "frontmatter" 'disable-model-invocation: true'
has "legacy line" 'refused: flat epic (tickets directly under the epic bead); the story skills do not handle it — the small-bug path does: /implement <ticket-id> per ticket, then bd close <epic-id>'
has "add-dir refusal" '/add-dir <'
hasc "Human stop" '**Human stop**'
hasc "Stall" '**Stall**'
hasc "Done" '**Done**'
has "Finished story" 'finished story'
hasc "finished story tolerates untriaged children" '`needs-triage` or `wontfix`'
lacks "finished story keyed on ready-for-human alone" 'other than `ready-for-human` ones|non-`ready-for-human`'
has "story orchestrator" 'story orchestrator'
has "implement-story" 'implement-story'
has "opus" 'opus'
hasc "waiting rule pointer" "the rules doc's Waiting"
has "resume command" '/implement-spec <KEY>-<n>'
has "Jira step pointer" '"the spec is done"'
has "Jira already-made read" 'getJiraIssue'
has "no-startable path" 'No startable story'
has "stopped state" 'stopped at <bead-id>'
has "orchestration pointer" 'orchestration.md'
has "preflight pointer" '"Working-directory preflight"'

fi

# ---- 2. WORKFLOW.md runbook ----
f=${2:-$root/docs/WORKFLOW.md}
runbook=$f
plugin=${PLUGIN_SKILLS:-$(ls -d "$HOME"/.claude/plugins/cache/claude-plugins-official/mattpocock-skills/*/skills 2>/dev/null | sort -V | tail -1)}
builtin=" model add-dir code-review "

# every /command token in file $1 maps to a skill directory (built-ins allowlisted)
cmds() { # <file>
  local tok name
  for tok in $(grep -oE '(^|[^A-Za-z0-9~._/-])/[a-z][a-z-]*(:[a-z-]+)?' "$1" | sed -E 's/^[^/]*\///' | sort -u); do
    name=${tok##*:}
    if [ "$name" != "$tok" ] && [ "${tok%%:*}" != "mattpocock-skills" ]; then bad "/$tok has an unknown namespace"; continue; fi
    case "$builtin" in *" $tok "*) continue;; esac
    [ -d "$skills/$name" ] && continue
    find "$plugin" -type d -name "$name" 2>/dev/null | grep -q . && continue
    bad "/$tok names no skill"
  done
}
if [ -f "$f" ]; then
echo "== $f"
cmds "$f"
# the cut skills take the feature as their one argument; the runbook has a paragraph on it and
# writes it in the 3a and 3b rows below (chezmoi-nz0)
hasc "argument paragraph" '**The argument.**'
fi
if [ -f "$skills/workflow/SKILL.md" ]; then
echo "== $skills/workflow/SKILL.md"
cmds "$skills/workflow/SKILL.md"
# /workflow prints each next command with the argument filled in, so a fresh session types it as-is
f=$skills/workflow/SKILL.md
hasc "workflow prints the story cut's argument" 'next: `/spec-to-stories <arg>`'
hasc "workflow prints the ticket cut's argument" 'next: `/spec-to-tickets <arg>`'
fi
f=$runbook
if [ -f "$f" ]; then

# flat /to-tickets appears only in the Variants section
awk '/^## /{sec=$0} /\/to-tickets/ && sec !~ /Variants/ {print NR": "$0; n=1} END{exit n}' "$f" >/dev/null \
  || bad "/to-tickets outside Variants"

# stale wording
for pat in 'cross-repo ticket' 'per-ticket `pr:`' 'single orchestrator' 'one orchestrator drives'; do
  grep -qiF -- "$pat" "$f" && bad "stale wording: $pat"
done
# session mode (ADR 0008): runbook-only retired wording is absent (section 5 sweeps the walk-up list), the mode is named
for pat in 'workspace **inbox**' 'resume from the home repo' "the home repo's story is a child"; do
  grep -qiF -- "$pat" "$f" && bad "retired wording: $pat"
done
hasc "workspace session named" 'workspace session'
hasc "cross-repo typed at the workspace root" 'typed at the workspace root'
hasc "resume from the workspace root" 'resume from the workspace root'
hasc "inbox is the home's beads" "the home's beads"

grep -E '^\| 4a \|' "$f" | grep -q sonnet && bad "sonnet at 4a in session-model table"

# required content
hasc "one-line flow" '/grill-with-docs → /to-spec → /spec-to-stories → /spec-to-tickets → /implement-spec → /close-epic'
hase "4a session model is opus" '^\| 4a \| opus'
hase "3a row" '^\| 3a \| `/spec-to-stories <KEY>-<n>`'
hase "3b row" '^\| 3b \| `/spec-to-tickets <KEY>-<n>`'
hase "1-3b session model is fable" '^\| 1–3b \| fable'
hasc "exploration notes path" '`<repo>/.spec-notes/<epic-id>/`'
lacks "story-cut.md in the runbook (the notes are the story bead's design field)" 'story-cut\.md'
for need in '/implement-story <story-id>' '/close-story' 'story bead' 'GLOSSARY.md'; do
  hasc "runbook content" "$need"
done
# the story DAG's runbook text (ADR 0011): add mode, and the human stop's merge-then-close line
# as the skills print it; the ticket cut's chain refusal is retired
hasc "add mode in the runbook" 'add mode'
hasc "human-stop merge line in the runbook" 'merge its PR, then run `/close-story <story-id>`'
hasc "printed human-stop line in the runbook" 'the PR to merge and the /close-story <story-id> to run'
lacks "chain refusal in the runbook" 'refus[a-z]*[^|]{0,60}dependency chain|dependency chain \(A depends'
hase "/pr named (Variants)" '/pr([^a-z-]|$)'

# /pr stays off the main line: the fenced flow block and stage 5
awk '/^```/{fence=!fence; next} fence && /\/pr([^a-z-]|$)/ {n=1} END{exit n}' "$f" || bad "/pr in the fenced flow"
grep -E '^\| 5 .*/pr([^a-z-]|$)' "$f" | grep -q . && bad "/pr in stage 5"

# the stage table stays one table (rows 1..8 contiguous)
awk '/^\| 1 \|/{on=1} on && !/^\|/{bad=1} /^\| 8 \|/{on=0} END{exit bad}' "$f" || bad "stage table broken by a non-row line"

fi

# ---- 3. /spec-to-stories ----
f=$skills/spec-to-stories/SKILL.md
if [ -f "$f" ]; then
echo "== $f"
has "frontmatter" 'disable-model-invocation: true'
has "preflight pointer" '"Working-directory preflight"'
has "epic gather pointer" '"gather the epic bead"'
# the argument is required; recovering the epic from the conversation or the open epic list
# is retired (chezmoi-nz0)
hasc "usage line" 'usage: /spec-to-stories <KEY>-<n>|<epic-id>'
lacks "no-argument epic recovery" 'bd list --type epic --json|open epic beads|reported in the conversation'
# the orientation goes to the story bead's design field; the story cut writes nothing in an owner
# repo but beads (chezmoi-cdf, ADR 0010)
hasc "design field write" 'update <story-id> --design-file -'
hasc "orientation header line" 'Orientation from the story cut; the story body is the only contract.'
hasc "beads-only writes in owner repos" 'writes no file and runs no git write in any owner repo'
lacks "step 8 gitignore line or commit" 'chore: ignore spec notes|Gitignore step commits it|\.spec-notes|>> <owner>/\.gitignore|git -C <owner> (add|commit)'
has "no Jira comment" 'No Jira comment'
has "the design field names the other repo of a pair" "the other repo's name"
has "repo-session line" 'repo session in <home>: one story, in the home repo'
has "repo-session refusal" 'refused: the spec changes <what> outside <home>; start this at the workspace root'
has "one test pointer" 'the one test'
has "workspace-session key warnings" 'in a workspace session'
lacks "re-sync instruction" 're-sync'
lacks "Jira comment step" 'addCommentToJiraIssue'
has "epic bead writes pointer" '"epic bead writes" convention'
# the stories form a DAG detected per edge, not a pair; the cut proposes a split of a repo's
# story only for a deprecate-then-remove, the user may split for any reason (ADR 0011)
has "story DAG" 'story DAG'
lacks "pair-wise dependency detection" 'for each pair of stories'
hasc "split proposed only for a deprecate-then-remove" 'only when the spec describes a deprecate-then-remove'
hasc "user split for any reason" 'split a repo'"'"'s story for any reason'
# a cut whose edges close a cycle is refused with the stories named, before any bead exists
hasc "cycle refusal" 'refused: the stories form a cycle (<repo> <story title> -> <repo> <story title> -> ...)'
hasc "cycle refused before any bead exists" 'stop before any bead exists'
hasc "cycle refused before step 7's epic bead" "that this run would create, step 7's epic bead included"
# the stories are listed, published and reported in topological order, each with one
# `## Blocked by` line per edge in both forms; the quiz and end report show every publish
lacks "pair-era dependency-first order" 'numbered list, dependency first'
hasc "topological order" 'topological order'
hasc "one blocker line per edge" 'one `## Blocked by` line per edge'
hasc "story-closure line form" 'a story-closure edge as `<repo> <story-id>`'
hasc "publish placeholder line form" 'a publish edge as `<dep repo> publish <crate> <version> (not created yet)`'
hasc "end report names each publish" 'publishes: <crate> <version> (from <current version>)'
hasc "end report names a story-closure edge" 'blocked by: <repo> <story-id>'
hasc "orientation names every edge" 'every edge of the story'
# the frontmatter says one story per PR (ADR 0011)
has "frontmatter: one story per PR" 'one story per PR, usually one per repo it changes'
lacks "frontmatter: one story per repo" 'one story per repo it changes'
# the deprecate-then-remove split's full shape, so it cannot trip its own cycle refusal: the
# removing half waits on each migrating story's closure, each migrating repo gets a second
# story bumping to the removal, and an importer's edge names the half it needs
hasc "removing half waits on the migrating stories" "the removing half waits on each migrating story's closure"
hasc "second migrating story bumps to the removal" "a second story that bumps to the removal's version"
hasc "importer names the half it needs" 'names the half it needs'
# a story waiting on a skipped story's closure is skipped too, with no invented line form
hasc "closure on a skipped story is skipped" "<repo> skipped: waits on <skipped repo>'s story"
lacks "invented closure line on a skipped story" '<story title> \(not created: no beads database\)'
# the skip cascades over closure and publish edges alike; only a story skipped for no beads
# database gets step 2's epic bead note, which is false for one skipped for waiting on it
hasc "skip cascades over both edge kinds" 'nor any story with an edge on it in turn, closure or publish'
hasc "epic bead note for a no-database skip" 'Record each story skipped for no beads database on the epic bead'
hasc "a waits-on skip is reported only" 'a story skipped for waiting on one is reported only'
lacks "epic bead note for every skipped story" 'Record each skipped story on the epic bead'
# a deploy split: the earlier story's paragraph names the deploy as its last step
hasc "deploy is the earlier story's last step" 'names the deploy as its last step'
# a cycle the user introduces at the quiz is rejected there; the skill keeps iterating
hasc "quiz cycle rejected, quiz continues" 'reject that change and keep iterating'
# the out-of-scope cases match the tracker doc's dependency section
hasc "ssh URL out of scope" 'pinned by git tag or ssh URL'
hasc "several crates in one story out of scope" 'several crates in one story'
# a feature whose stories exist enters add mode; the refusal stays only when every story is
# closed (ADR 0011)
has "add mode" 'add mode'
lacks "unconditional stories-exist refusal" 'refused: stories exist'
hasc "refusal only when every story is closed" 'refused: every story is closed'
hasc "add mode shows each story's state" 'finished, open with failed tickets, waiting'
hasc "add mode reads the failed twice: notes" 'names the `failed twice:` reason it answers'
hasc "add mode quizzes the additions only" 'quizzes the additions only'
# one forge query per finished story an addition touches, sandbox-disabled as /close-story's
hasc "forge query, GitHub" 'gh pr view <url> --json state'
hasc "forge query, Forgejo/Gitea" 'tea api --repo <owner> repos/{owner}/{repo}/pulls/<n>'
lacks "Forgejo/Gitea forge query without --repo" 'tea api repos/'
hasc "forge query runs sandbox-disabled" 'with the sandbox disabled, as `/close-story` step 4 does'
hasc "MERGED forces a new story on the old one's closure" 'a new story blocked on its closure and on the new publish'
hasc "MERGED reminds the close" 'run `/close-story <story-id>`'
hasc "OPEN defaults to a re-cut" '`OPEN` defaults to a re-cut'
hasc "no forge or a branch-form pr: asks the user" 'a branch-form `pr:` value asks the user'
# OPEN's re-cut marks the finished dependent so the ticket cut may re-cut it past its pr: note;
# a PR closed unmerged is refused, as /implement-story's merge guard refuses it (story review 1)
hasc "OPEN marks the finished dependent for a re-cut" '`recut: <dep repo> publish <crate> <version>`'
hasc "a PR closed unmerged is refused" 'refused: PR <url> is closed unmerged'
lacks "a PR closed unmerged takes OPEN's path" 'closed unmerged is not sealed|closed unmerged[^.]*takes `OPEN`'
# step 7 in add mode writes the additions and the rewritten dependent bodies, beads only
hasc "add mode publishes the additions only" 'publishes the additions only'
hasc "open dependent's body rewritten" 'update <story-id> --body-file -'
hasc "add mode leaves Jira untouched" 'the Jira description is untouched'

fi

# ---- 4. /spec-to-tickets driver ----
f=$skills/spec-to-tickets/SKILL.md
if [ -f "$f" ]; then
echo "== $f"
has "frontmatter" 'disable-model-invocation: true'
has "no-stories refusal" 'refused: no stories'
has "every-story-cut refusal" 'refused: every story already cut'
has "every-story-cut remedy" 're-cut one with /story-to-tickets <story-id>'
has "preflight pointer" '"Working-directory preflight"'
has "epic gather pointer" '"gather the epic bead"'
# the same argument rule as /spec-to-stories (chezmoi-nz0)
hasc "usage line" 'usage: /spec-to-tickets <KEY>-<n>|<epic-id>'
lacks "no-argument epic recovery" 'ended on in the conversation|ask the user for it'
has "already cut line" '<repo> <story-id> already cut'
hasc "waiting rule pointer" 'the "Waiting" rule of `orchestration.md`'
has "no model override" 'no `model:` override'
has "waiting line" 'waiting on <dep repo> cut'
has "closed story line" '<repo> <story-id> closed'
has "skipped dependent gets explicit crate and version" 'Dependent: <repo>, skipped: no beads database, crate <crate>, version <version>.'
lacks "crate and version deferred to the notes" 'as story-cut.md has them|as the design field has them'
has "skipped dependent's crate and version read from the design field" 'design field'
lacks "owner-repo notes file" '\.spec-notes'
has "already-cut block carries What to build" '`## What to build` paragraph'
has "all-closed refusal" 'refused: every story closed'
has "closed-uncut dependency line" 'dependency story closed uncut'
has "failed publish line" '<repo> <story-id> publish failed: <reason>'
has "dependent of a failed publish line" 'waiting on <dep repo> publish'
has "dependency cut without a publish ticket waits" 'has no `publish <crate> <version>` child'
has "closed-uncut remedy reopens the dependency" 'bd -C <repo> reopen <id>'
has "Jira comment covers every story" 'every story of the feature that has tickets'
lacks "Jira comment limited to this run" 'tickets this run published'
lacks "re-sync instruction" 're-sync'
has "one test pointer" 'the one test'
has "epic bead writes pointer" '"epic bead writes" convention'
lacks "story-cut procedure" 'Resolve the spec to its repos|Draft the stories|Quiz the user on the stories|Write the story-cut notes'
# the ticket cut cuts the story DAG (ADR 0011, chezmoi-9v4.1.8): a cycle is refused naming its
# stories; cutters run in topological waves, one per DAG level, each dependent's brief carrying
# every upstream breakdown, a story-closure edge ordering no wave; an already cut dependent of a
# new publish ticket is re-cut by the driver in the same run, so the rerun hint drops that case
has "cycle refusal names the stories" 'refused: dependency cycle ('
has "topological waves" 'topological waves'
has "one wave per DAG level" 'one wave per level of the story DAG'
has "dependent brief carries every upstream breakdown" 'one `Dependency:` line per publish blocker'
has "story-closure edge orders no wave" 'a story-closure edge orders no wave'
has "driver re-cuts an already cut dependent" 're-cuts that dependent itself'
has "the re-cut adds a second bump" 'second bump'
# a skipped repo's publish line has no dependency story; the inline re-cut is keyed on the
# missing bump; a finished dependent is excluded at step 1, and a failed re-cut of a dependency
# that has its publish ticket holds no dependent back (chezmoi-9v4.1.8 review 1)
has "skipped publish line is an edge with no dependency" 'an edge with no dependency in the run'
has "re-cut keyed on the missing bump" 'has no bump child titled with that crate'
has "finished dependent excluded at step 1" 'cut failed: finished story (pr: note present)'
has "failed re-cut with a publish ticket holds nothing" 'already has its publish ticket holds nothing'
hasc "re-cut dependent also waits on a dependency without its publish" 'A dependent of the run (in the set to cut or to re-cut) with such an edge'
# a re-cut dependent that is also a dependency joins the trigger until no story joins, and no
# dependent waits on a publish the run creates; the cut-failure cascade covers only the run's
# dependencies, after the closed-uncut rule, so no story gets two report lines (review 2)
has "re-cut dependent without its publish joins the trigger" 'a dependent to re-cut without its publish ticket'
has "trigger applied to a fixed point" 'applied until no story joins'
has "no wait on a publish the run creates" 'and is not re-cut in this run'
has "cascade narrowed to the run's dependencies" 'a dependency of the run whose cutter failed or that was itself held back'
hasc "closed-uncut rule stands on its own" 'Nor is a dependent spawned whose dependency story is `closed` with no children'
has "re-cut line is a progress line" 'a step-1 progress line'
# a finished dependent add mode marked with a recut: note is re-cut for that edge; the
# all-closed refusal gives the live reason, not the retired stories-exist one (story review 1)
has "finished dependent re-cut on its recut: note" 'a `recut:` line for that edge'
lacks "retired stories-exist reason" 'since stories exist'
lacks "two-wave cap or chain refusal" 'two (dependency )?waves suffice|two suffice|at most two( dependency)? waves|chains are out of scope'
lacks "rerun hint covering an already cut dependent" 'rerun this skill for the dependent'

fi

# ---- 5. agent docs and skills: retired phrases ----
echo "== $agents, $skills"
# whole words only ("shortcut one", "cut ones" pass); "re-cut one" is the spec's wording, not the retired name
retired='(^|[^-A-Za-z0-9_])cut (one|two)([^-A-Za-z0-9_]|$)|<spec-slug>|story-cut\.md'
# and no foreground spawn instruction: an Agent call returns at once whatever run_in_background
# says, so skills and agent docs point at the waiting rule instead (chezmoi-p4q)
while IFS= read -r f; do
  lacks "retired phrase in $f" "$retired"
  lacks "foreground spawn instruction in $f" 'run_in_background: false'
done < <(find "$agents" "$skills" -type f 2>/dev/null | sort)

# two lists are retired everywhere a reader meets them, the four file kinds: the skills, the
# agent docs, the project CLAUDE.md and the runbook (section 2's file).
# Session mode (ADR 0008): the walk-up wording.
walkup='nearest ancestor|walking up|walk up|one level up|the home repo included|the workspace root included|no repos\.yaml above|workspace inbox|workspace'\''s inbox|home repo <home repo>'
# The story-DAG wording (ADR 0011): one story per repo (now one per PR), the keyed branch
# feat/<key>-<n> (now feat/<story-id>), chains out of scope and the one text blocker (now a
# DAG), and the two-wave cap (now topological waves).
retired_dag='one story per repo|feat/<key>-<n>|chains are out of scope|only text blocker|two waves suffice'
while IFS= read -r f; do
  lacks "retired walk-up wording in $f" "$walkup"
  lacks "retired story-DAG wording in $f" "$retired_dag"
done < <({ find "$agents" "$skills" -type f 2>/dev/null; echo "$user_claude_md"; echo "$runbook"; } | sort)

# ---- 6. shared rules the skills point at ----
f=$agents/orchestration.md
if [ -f "$f" ]; then
echo "== $f"
hasc "preflight section" '## Working-directory preflight'
has "preflight remedy" '/add-dir <'
# a runner waits on its subagent's report, never on a Bash poll loop; pgrep is dead in the sandbox (chezmoi-flq)
hasc "waiting rule" '**Waiting.**'
hasc "pgrep unusable in the sandbox" '`pgrep` cannot list processes in the sandbox'
# an Agent call returns at once in this harness, so an orchestrator ends its turn after spawning
# and the child's report arrives as the Agent tool's completion notification; run_in_background
# is a JSON boolean the probe found ignored or absent for a nested agent; every subagent below
# the driver runs Bash in the foreground only, since a child that ends a turn with background
# work running counts as idle and its real report escapes to the top-level session (chezmoi-p4q)
hasc "an Agent call returns at once" 'An Agent call returns at once'
hasc "the completion notification carries the report" "the Agent tool's completion notification"
hasc "a nested orchestrator ends its turn after spawning" 'ends its turn'
hasc "run_in_background is a JSON boolean" '`run_in_background` is a JSON boolean'
hasc "idle rule" '**Idle rule.**'
hasc "Bash in the foreground only below the driver" 'in the foreground only'
lacks "a foreground spawn" 'spawns in the foreground|foreground spawn returns|has no notification to wait for'
# the merger's wait on the owner checkout's lock is the one shell wait, a bounded foreground
# until-loop, since a background call ends the merger's turn early (chezmoi-sn1, the idle rule)
hasc "merger lock wait is the one shell wait" 'The one shell wait'
# the typed implement command is the authority to push and open the PR, so the push is a step
# of the run, with a failed: line when it is refused (ADR 0009, chezmoi-g61)
hasc "delivery rule" '**Delivery.**'
lacks "profile-gated push in the rules doc" 'when the active profile permits'
# the epic-level stages reach an owner repo only through its beads database; files, .gitignore
# and commits there are the story orchestrator's (chezmoi-cdf, ADR 0010)
hasc "beads-only principle for the epic-level stages" 'only through its beads database'
lacks "the story cut commits the /.spec-notes/ line" 'The story cut commits'
# a ticket whose runner ended without closing it keeps its claim and bd ready omits it, so the
# story orchestrator unclaims it; a human does so only when the orchestrator could not (chezmoi-jvc)
hasc "frontier unclaim rule" '**Unclaim.**'
# the frontier admits only ready-for-agent tickets, not merely those without ready-for-human,
# so a needs-triage child filed under a story never gets a runner (chezmoi-wgi)
hasc "frontier admits ready-for-agent only" 'it is labelled `ready-for-agent`'
lacks "frontier keyed on ready-for-human alone" 'it is not labelled `ready-for-human`'
hasc "finished story tolerates untriaged children" '`needs-triage` or `wontfix`'
# every worktree brief starts by exporting a gitignored repo-relative TMPDIR, since the macOS
# default is unwritable in the sandbox (mktemp -d, heredocs); the export is repeated per Bash
# call and mktemp -d takes a template, since macOS mktemp ignores TMPDIR (chezmoi-3eg)
hasc "TMPDIR rule" '**TMPDIR.**'
# the rule's own paragraph (from its heading to the next blank line) carries the line, the two
# failures and the gitignore fact, so a word used elsewhere in the doc cannot stand in
para() { awk -v h="$1" 'index($0, h) == 1 {on=1} on && /^$/ {exit} on {print}' "$f"; }
para_has() { para "$1" | grep -qiF -- "$3" || bad "missing in the $1 paragraph: $2 ($3)"; }
para_has '**TMPDIR.**' "TMPDIR line" 'mkdir -p <worktree>/.tmp && export TMPDIR=<worktree>/.tmp'
para_has '**TMPDIR.**' "the heredoc failure" 'heredoc'
para_has '**TMPDIR.**' "the directory is gitignored" '`.tmp/` is gitignored'
para_has '**TMPDIR.**' "export repeated per Bash call" 'export TMPDIR=<worktree>/.tmp; <command>'
para_has '**TMPDIR.**' "mktemp -d takes a template under .tmp" 'mktemp -d <worktree>/.tmp/<name>.XXXXXX'
para_has '**Gitignore.**' "/.tmp/ among the Gitignore rule's entries" '`/.tmp/`'
# a reviewer tags every finding blocking or minor and ends on a verdict line; a round with no
# blocking findings is clean and only blocking rounds count toward the three-round limit. The
# rule is stated once here; the runner brief and the story review point at it (chezmoi-49k)
hasc "Review verdict rule" '**Review verdict.**'
para_has '**Review verdict.**' "the clean verdict line" 'verdict: clean'
para_has '**Review verdict.**' "the blocking verdict line" 'verdict: blocking (<n>)'
para_has '**Review verdict.**' "the blocking-or-minor tags" '**blocking** or **minor**'
para_has '**Review verdict.**' "a round with no blocking findings is clean" 'no blocking findings is **clean**'
para_has '**Review verdict.**' "only blocking rounds count toward the limit" 'Only blocking rounds count'
fi
f=$agents/issue-tracker.md
if [ -f "$f" ]; then
echo "== $f"
# the one test of the session mode (ADR 0008), stated once, in the opening before any section
opening() { awk '/^## /{exit} {print}' "$f"; }
for need in '`<home>` is the session'"'"'s repo' '`<home>/repos.yaml`' '**workspace session**' '**repo session**' 'the only owner'; do
  opening | grep -qF -- "$need" || bad "missing in the tracker doc's opening: the one test ($need)"
done
hasc "epic gather section" 'When a skill says "gather the epic bead"'
has "other-repo refusal" 'refused: epic bead lives in <repo>'
has "closed refusal" 'refused: epic bead is closed'
has "flat epic refusal" 'refused: flat epic (tickets directly under the epic bead)'
has "re-cut creates a missing publish ticket" 'has no publish ticket'
lacks "Jira comment gated on every ticket" "When all of a run's tickets are published"
hasc "spec fetch section" 'When a skill says "fetch the spec"'
has "Spec: file fallback" 'The file a `Spec: <path>` line'
# the line's one canonical form, stated in the gather section and read by the fallback (chezmoi-dz4)
has "Spec: line canonical form" '`<path>` relative to the epic bead'"'"'s repo'
# who may write on the epic bead, stated once and cited by the three cut skills (chezmoi-f0f)
hasc "epic bead writes convention" '- Epic bead writes:'
# the close check counts a story's children the way the finished-story definition does: an
# untriaged child an earlier run left under the story holds back neither its PR nor its close
# (chezmoi-afn)
hasc "close rule tolerates untriaged children" 'closed or carries `needs-triage` or `wontfix`'

fi

# ---- 7. /story-to-tickets ----
f=$skills/story-to-tickets/SKILL.md
if [ -f "$f" ]; then
echo "== $f"
has "spec fetch pointer" 'Fetch the spec as the tracker doc'"'"'s "fetch the spec" says'
has "story cutter trigger" '**Called, draft role ("story cutter"'
has "publish trigger" 'opens `Publish this block`'
hasc "design field read" '.[0].design'
lacks "owner-repo notes file" '\.spec-notes'
has "one test pointer" 'the one test'
has "home name in the Parent line template" 'home <home name>'
has "epic bead writes pointer" '"epic bead writes" convention'
# the pair is read per edge of the story DAG (ADR 0011): a dependent for each publish
# blocker, one bump per publish blocker, a dependency when it holds a publish ticket
has "pair read per edge" 'Dependency pair, per edge'
has "one bump per publish blocker" 'one bump per publish blocker'
has "brief carries a Dependency line per publish blocker" 'one `Dependency:` line per publish blocker'
has "brief carries a Dependent line per dependent" 'one `Dependent:` line per dependent'
# the two refusals: two publish tickets in one story, and a finished story pointing at add mode
has "two publish tickets refusal" 'refused: block carries two publish tickets; one PR publishes one version'
has "finished-story refusal names add mode" 'add mode (/spec-to-stories <KEY>-<n>, or the epic bead id when the story has no key)'
has "finished story marked by add mode is re-cut" 'unless its notes carry a `recut:` line'
# a re-cut that gained a publish blocker adds a second bump and re-edges open tickets
has "re-cut adds a bump per new publish blocker" 'gained a publish blocker'
has "re-cut re-edges kept tickets onto the new bump" 'kept ones with `bd dep add <ticket id> <bump id>`'
has "re-cut matches a bump to its blocker by crate" 'a bump covers the blocker whose crate its title names'
has "publish ticket line shapes" 'a line names a publish ticket when it reads'
has "re-cut cites the tracker doc's per-edge rules" 'the tracker doc'"'"'s per-edge re-cut rules'

fi

# ---- 8. /implement-story: the deliver step pushes and opens the PR on the typed command's authority ----
f=$skills/implement-story/SKILL.md
if [ -f "$f" ]; then
echo "== $f"
hasc "delivery rule pointer" 'the rules doc'"'"'s Delivery'
hasc "push command" 'git -C <owner> push -u origin <branch>'
hasc "refused push is a failed line" 'failed: push'
lacks "profile-gated push" 'when the active profile permits|ask the user to run that exact command|give the user that exact command'
hasc "gitignore commit keyed on a dirty file" 'git -C <owner> status --porcelain -- .gitignore'
lacks "a gitignore hand-off from the story cut" 'the story cut appended|story cut could not commit'
hasc "a user edit in .gitignore is a failed: line, not absorbed" 'failed: <owner>/.gitignore has uncommitted edits'
hasc "exploration subagent reads the design field" '.[0].design'
hasc "exploration subagent owns the notes directory" '`<owner>/.spec-notes/<epic-id>/`'
# a failed runner's ticket is unclaimed at once, a second failure leaves the resume pointer on
# it, and the resume section says when a human runs the unclaim instead (chezmoi-jvc)
hasc "a failed runner's ticket is unclaimed" 'first `bd -C <owner> unclaim <id>`'
hasc "second failure notes the resume pointer" 'failed twice: <reason>; resume:'
hasc "hand unclaim condition in the resume section" 'by hand only when'
# the frontier keeps only ready-for-agent tickets, a deferred review finding is captured in the
# inbox through the retro capture and never as a story child, and a story counts as finished
# with an untriaged child under it (chezmoi-wgi; the Frontier rule itself is checked in 6)
hasc "frontier keeps ready-for-agent tickets only" 'keeping only the tickets labelled `ready-for-agent`'
lacks "frontier minus ready-for-human alone" 'minus `ready-for-human` tickets|other than `ready-for-human` ones|non-`ready-for-human`'
hasc "deferred findings go through the retro capture" '"capture a retro item"'
hasc "finished story tolerates untriaged children" '`needs-triage` or `wontfix`'
# the merger waits on the owner checkout's lock in one bounded foreground until-loop, not a
# check-and-sleep loop the merger runs by hand (chezmoi-sn1; the Waiting rule is checked in 6)
hasc "merger waits on the lock with an until-loop" 'until ! [ -e <owner>/.git/index.lock ]'
hasc "merger's lock wait is bounded by the call's timeout" 'timeout: 300000'
lacks "merger sleeping and re-checking the lock by hand" 'waits [0-9]+ seconds|checks again|re-?checks the lock|checks every [0-9]+ seconds'
# the story orchestrator and the ticket runner end their turn after spawning and are resumed by
# the completion notification; the runner and its subagents run Bash in the foreground only
# (chezmoi-p4q; the rule itself is checked in 6)
hasc "frontier spawn ends the turn" 'then end your turn: each runner'
hasc "ticket runner's spawn ends the turn" 'then end your turn: its report'
hasc "ticket runner brief carries the idle rule" "the rules doc's Idle rule"
# one story is one PR on `feat/<story-id>` (keyed or not); a finished story with an open agent
# ticket is guarded by one forge query; a story-closure wait says to merge and close; the
# sibling line carries the story id (chezmoi-9v4.1.5, ADR 0011)
hasc "integration branch is feat/<story-id> for keyed and keyless stories" 'named `feat/<story-id>`, keyed or not'
lacks "the keyed branch form feat/<key>-<n>" 'feat/<key>-<n>'
hasc "merge guard names the delivered story with an open agent ticket" 'a delivered story with an open `ready-for-agent` ticket'
hasc "merge guard covers a pr: line, a URL or the branch form" 'whose notes carry a `pr:` line'
hasc "merge guard's MERGED refusal says add mode" 'in add mode (or /spec-to-stories'
hasc "merge guard's MERGED refusal closes the stray ticket" '; then close <ticket-id> (moved to the new story)'
hasc "step 3 defers to the forge decision of the merge guard" '(already decided in step 1 when the merge guard ran)'
hasc "merge guard decides the forge as step 3 does" 'the forge decided as step 3 says'
hasc "merge guard's Forgejo query names the repo" 'tea api --repo <owner> repos/{owner}/{repo}/pulls/<n>'
hasc "merge guard refuses a PR closed unmerged" 'CLOSED unmerged: refuse'
hasc "merge guard's add-mode hint covers an epic with no external ref" '(or /spec-to-stories <epic-id> when the epic has no external ref)'
hasc "merge guard runs the forge query sandbox-disabled" 'with the sandbox disabled, as `/close-story` step 4 does'
hasc "merge guard refuses a MERGED PR" 'MERGED: refuse'
hasc "merge guard: OPEN continues on the branch: note's branch" "OPEN: continue on the \`branch:\` note's branch"
hasc "merge guard asks when the forge cannot tell" '(no forge, or a branch-form `pr:` note)'
hasc "merge guard asks whether the PR or branch has merged" 'whether the PR, or for the branch form the branch, has merged into the default branch'
hasc "merge guard leaves the stray ticket until add mode carries its work over" 'until add mode has carried its work into a new story, so close it there then'
hasc "story-closure wait says to merge the PR and run /close-story" 'merge its PR and run /close-story <blocker-id>`'
hasc "a keyless story's branch is still feat/<story-id>" 'its branch is `feat/<story-id>`, as every story'"'"'s is (step 3)'
hasc "merge guard fires on a child that is not closed" 'while a child that is not closed (open, in_progress or blocked) is labelled `ready-for-agent`'
hasc "merge guard decides the branch form locally first" '`git -C <owner> merge-base --is-ancestor <tip SHA> origin/<default branch>`'
hasc "merge guard ends a spawned run with a failed: line" 'failed: <story-id> merge state unknown (<pr: value>): say whether it merged, then re-run'
hasc "merge guard summary says the branch form is decided locally first" 'the branch form or no forge is decided locally first, then asked (below)'
hasc "merge guard maps each ancestry exit and a failed fetch" '(exit 0: as MERGED; exit 1: as OPEN; a failed fetch of an existing origin or any other exit: it cannot decide (ask))'
hasc "merge guard skips the fetch with no origin" '`git -C <owner> fetch origin` (skipped with no `origin`), then'
hasc "merge guard finds the default branch as step 3 says" 'find `<default branch>` as step 3 says; with no `origin`, compare against the local `<default branch>`'
hasc "sibling line format carries the story id" '`<repo> <story-id> <url>`'
lacks "the sibling line as <repo> <url>" '`<repo> <url>`'
lacks "glossary's avoided term human ticket" '(^|[^-])human ticket'
# step 9 removes worktrees with the sandbox disabled up front (the sandbox denies deletes under
# .git/worktrees/ and no setting lifts that), never as a retry after the denial; it sweeps every
# worktree-agent-* and .worktrees/ worktree whose branch is merged into the integration branch,
# earlier runs' included, and reports a locked or unmerged one in the worktrees: line instead of
# forcing it (chezmoi-73d)
hasc "worktree removal runs sandbox-disabled up front" 'worktree prune` run with the sandbox disabled'
lacks "worktree removal retried sandbox-disabled only after the denial" 'retry that one command with the sandbox disabled'
hasc "the sweep covers harness and hand-rolled worktrees" 'whose branch is `worktree-agent-*` or whose path is under `<owner>/.worktrees/`'
hasc "the sweep is keyed on the branch being merged into the integration branch" 'merged into `<branch>`'
lacks "the sweep limited to this run's worktrees" 'every worktree the run made'
hasc "a locked or unmerged worktree is reported, not removed" 'reported with its path'
lacks "a locked or unmerged worktree forced" 'worktree remove[^`]* -(-force|f)'
hasc "report template shows the worktrees: line" 'worktrees: <absolute path>'
hasc "the worktrees: line appears only with content" '`worktrees:` and `resume:` lines appear only when they have content'
# the implementer, fix-up implementer and merger briefs start with the TMPDIR line, stated once
# in the Owner repo section with its two riders and named in the ticket runner brief's steps 2,
# 3 and 4 and the story review's fix-up (step 7); the Gitignore step counts the rule's four
# entries, /.tmp/ included (chezmoi-3eg)
hasc "TMPDIR line stated in the skill" 'mkdir -p <worktree>/.tmp && export TMPDIR=<worktree>/.tmp'
hasc "export repeated per Bash call" 'repeated at the head of every Bash call'
hasc "mktemp -d takes a template under .tmp" 'mktemp -d <worktree>/.tmp/<name>.XXXXXX'
# the ticket runner reads the rules doc, not this skill, so its brief points there
hasc "ticket runner brief points at the rules doc's TMPDIR rule" "the rules doc's TMPDIR rule"
for step in 2 3 4; do
  grep -qE "^> $step\. .*TMPDIR line" "$f" || bad "missing: ticket runner step $step's brief starts with the TMPDIR line"
done
grep -qE '^7\. .*TMPDIR line' "$f" || bad "missing: the story review's fix-up implementer brief starts with the TMPDIR line"
hasc "Gitignore step counts four entries" "the rule's four entries"
lacks "Gitignore step counts three entries" "the rule's three entries"
# the reviewer brief in the runner's step 3 carries the two tags with their definitions and
# the verdict line (the reviewer never reads the rules doc), and step 3 and the story review's
# step 7 point at the rules doc's Review verdict for what a clean round does; the retired bar,
# clean as no finding at all, is gone (chezmoi-49k). The brief's phrases are read on the step 3
# line alone, since step 7 carries the same ones
for phrase in 'verdict: clean' 'verdict: blocking (<n>)' '**blocking** or **minor**' 'at most three blocking rounds'; do
  grep -E '^> 3\. ' "$f" | grep -qF -- "$phrase" || bad "missing: ticket runner step 3's reviewer brief ($phrase)"
done
grep -qE "^> 3\. .*the rules doc's Review verdict" "$f" || bad "missing: ticket runner step 3 points at the rules doc's Review verdict"
grep -qE "^7\. .*the rules doc's Review verdict" "$f" || bad "missing: the story review (step 7) points at the rules doc's Review verdict"
lacks "the zero-findings bar" 'not clean after three rounds|no findings at all|clean means zero findings'

fi

# ---- 9. /close-story: the ticket check counts children as the finished-story definition does ----
f=$skills/close-story/SKILL.md
if [ -f "$f" ]; then
echo "== $f"
# a child carrying needs-triage or wontfix is a note with nothing to implement, not a ticket
# to wait for; any other open child is named with its status and label, so the remedy is
# readable from the refusal line (chezmoi-afn)
hasc "ticket check skips untriaged children" 'carries `needs-triage` or `wontfix`'
hasc "refusal names status and label" 'open tickets <child> <status> <label>'
lacks "refusal without the label" 'open tickets <child> <status>, \.\.\.'

fi

# ---- 10. the story DAG in the tracker and orchestration docs (ADR 0011) ----
# a feature's stories form a DAG of text blockers, each naming a human gate ticket or a story;
# the one-text-blocker and no-chains rules are retired. The skills and the runbook get their
# own checks in their sections, so the forbidden phrases are scoped to these two docs.
for f in "$agents/issue-tracker.md" "$agents/orchestration.md"; do
  [ -f "$f" ] || continue
  echo "== $f"
  has "story DAG" 'story DAG'
  has "human gate ticket" 'human gate ticket'
  # read as one line, so a phrase wrapped across a line break is still caught; the chains
  # match is bounded so it cannot run across paragraphs
  for pat in 'only text blocker' 'chains[^.]{0,120}out of scope'; do
    tr '\n' ' ' < "$f" | grep -qiE -- "$pat" && bad "present: retired story-DAG wording in $f ($pat)"
  done
done
# a story held only by a story-closure blocker ends the run as a human stop naming the merge
# and the /close-story; a publish ticket waits on its story's tickets, not its repo's
f=$agents/orchestration.md
if [ -f "$f" ]; then
echo "== $f"
hasc "story-closure human stop" 'merge its PR, then run `/close-story <story-id>`'
has "publish ticket ready on its story's tickets" "as soon as its story's implementation tickets close"
lacks "publish ticket ready on its repo's tickets" "its repo's implementation tickets close"
fi
# the story body shows only blocker lines a step fills; a middle story of a chain is ordered
f=$agents/issue-tracker.md
if [ -f "$f" ]; then
echo "== $f"
lacks "gate ticket line no step fills" '<repo> <gate ticket id>'
# the story cut writes a story line or a publish placeholder (step 2's skipped form too), so
# "the only lines" of step 4 would contradict step 2
has "story cut writes no gate ticket id" 'never a line naming a gate ticket id'
lacks "story cut's lines contradict step 2" 'the only lines the story cut writes'
has "middle story of a chain" 'in the middle of a chain'
# a repo session may hold several home stories, each the epic bead's child, or the stories
# gather (bd children <epic-id>) misses one; the ticket cut is one topological pass, since a
# dependency wave is one batch of cutters per DAG level and never splits a story
has "every repo-session story under the epic" '# repo session: every story'
lacks "one home story with a parent" 'Only the home story has a parent'
has "ticket cut in one topological pass" 'one topological pass'
# the pass is per story, not per edge: a dependent with two publish blockers gets every bump
# before its other tickets (steps 4 and 5)
has "ticket cut ordered per story" 'one topological pass over the stories'
lacks "ticket cut ordered per edge" 'one topological pass over the edges'
lacks "middle story split across waves" 'opens its own wave'
has "deploy split waits on the earlier story's closure" 'that `/close-story` requires closed'
# a re-cut blocks every open ticket but the bumps on every bump, so no bump blocks on itself
# or on another bump and step 5 holds
has "re-cut exempts the bumps" 'every open ticket of the story that is not a bump'
lacks "re-cut blocks a bump on itself" 'every open ticket of the story is blocked'

fi

# version-bump rule: a diff under skills/ or docs/ needs a version change in the plugin manifest.
# The diff runs from VERSION_BUMP_BASE (CI sets it to the PR base) or else the merge-base with
# main, to HEAD; VERSION_BUMP_REPO overrides the repo (the regression test's throwaway repo).
# A no-op on main itself, and in a tree that is not a git repo.
bump_repo=${VERSION_BUMP_REPO:-$root}
if git -C "$bump_repo" rev-parse --git-dir >/dev/null 2>&1 \
  && [ "$(git -C "$bump_repo" rev-parse --abbrev-ref HEAD 2>/dev/null)" != main ]; then
  echo "== version bump"
  base=${VERSION_BUMP_BASE:-$(git -C "$bump_repo" merge-base main HEAD 2>/dev/null)}
  if [ -z "$base" ]; then
    bad "version bump: no diff base (no main branch to merge-base with; set VERSION_BUMP_BASE)"
  elif [ -n "$(git -C "$bump_repo" diff --name-only "$base" HEAD -- skills docs)" ]; then
    manifest=.claude-plugin/plugin.json
    old=$(git -C "$bump_repo" show "$base:$manifest" 2>/dev/null | grep -F '"version"')
    new=$(git -C "$bump_repo" show "HEAD:$manifest" 2>/dev/null | grep -F '"version"')
    [ "$old" != "$new" ] || bad "version bump: skills/ or docs/ changed since ${base:0:9} but $manifest has no version change"
  fi
fi

[ "$fail" = 0 ] && echo "PASS"
exit "$fail"
