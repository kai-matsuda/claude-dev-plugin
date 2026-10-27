# Fix-up budgets are bounded per invocation

## Problem Statement

dev-94a (bd0af91) made a fresh ticket or story orchestrator start its unit's fix-up budget
at three whatever earlier runs noted, and kept the epic row as the exception: it spans
runs while its PRs wait on their checks, so `/dev:implement-spec` step 6 counts each
story's budget from its `epic fix-up` notes and skips a story that already has three with
a blocking last review. The exception has three costs. A story that failed its epic review
after three fix-ups is never reviewed again: no typed command revives it, so a person who
amends the Jira spec overnight has no way to get the story re-reviewed short of closing
the PR and re-cutting. The Check gate rule is two rules, one per row kind, and the second
contradicts what the docs already say about typing the command again ("a deliberate new
attempt"). And the count lives in notes that nothing delimits, so a resumed epic
orchestrator cannot tell this run's fix-ups from last week's. The person running the
workflow wants one bound: three fix-up rounds per unit per human invocation, at every row.

## Solution

One rule at every row. A budget is three fix-ups per unit per **invocation**, one typed
`/dev:implement-spec` or `/dev:implement-story` from the command to its end state, and
only a person typing the command again grants more. The epic row stops being the
exception. Its count is derived from the story's notes, delimited by the invocation's own
first review: every invocation's first review of a story writes `epic review 1`, so the
budget a story has spent is the number of `epic fix-up` notes after its last `epic review
1` note. Both `<k>`s on a story bead, review and fix-up, count this invocation's ordinals.
Step 6's skip of a story with three fix-up notes and a blocking last review is deleted: a
finished story with an open draft PR is reviewed by every invocation until its verdict is
clean or a person closes the PR, and the Stall end state tells the person those are the
two exits. Vocabulary in `GLOSSARY.md` (Invocation, Check gate), already written.

## User Stories

1. As the person running a feature, I want every retry bound to be per invocation, so
   that typing the command again is always a full new attempt, at the epic row as at the
   others.
2. As the person running a feature, I want a story that failed its epic review to be
   reviewed again on my next invocation, so that amending the spec and typing the command
   is enough to revive it.
3. As the person running a feature, I want the Stall report to tell me the two ways out
   of a failed epic review, amend and rerun or close the PR, so that I do not have to read
   the skill to learn them.
4. As the epic orchestrator, I want each story's spent budget derived from its notes
   after this invocation's `epic review 1`, so that I hold no count in context and a
   compacted continuation counts the same as an uninterrupted turn.
5. As the epic orchestrator on a fresh invocation, I want last week's three `epic fix-up`
   notes to count for nothing, so that I never refuse a story before its first review.
6. As the epic orchestrator, I want `epic review <k>` and `epic fix-up <k>` to share one
   meaning of `<k>`, this invocation's ordinal, so that the report's `fix-up <k> of 3`
   is true and the next reader of step 6 learns one rule.
7. As the epic orchestrator, I want step 6's re-poll of pending checks and my continuation
   after a session limit to be the same invocation, so that neither grants a story more
   rounds.
8. As the epic orchestrator, I want closed stories and landed or closed PRs left out of the
   review set as today, so that reviving a failed story never means reopening anything.
9. As a reader of the rules doc, I want the Check gate to state the budget rule once for
   every row with the reason the exception was dropped, so that I do not reconstruct it
   from a bead.
10. As a reader of the docs, I want **Invocation** in the glossary and the docs to say
    "invocation" where they mean one, so that "run" stops meaning a typed command in one
    sentence and a check in the next.
11. As a maintainer of the plugin, I want each new rule pinned by the skill-doc lint and
    each dropped rule pinned as absent, each with its regression case, so that a later
    edit cannot bring the exception back silently.

## Implementation Decisions

- **Vocabulary.** One new glossary entry, already written: **Invocation** (one typed
  `/dev:implement-spec` or `/dev:implement-story`, from the command to its end state,
  including its re-polls and its continuation after a session limit; every fix-up budget
  is bounded per invocation; avoid "typed run", "fresh run", and "attempt" for one
  invocation). The **Check gate** entry now says "per invocation". Where the docs say
  "run" for a typed command they say "invocation": the Check gate paragraph, the
  implement-spec skill's steps 5 to 7, and the glossary's **Human stop** and **Stall**
  entries ("the end of an invocation of"). "Run" stays where it means a stage's run in
  the runbook or a run of the check command.
- **The Check gate** (`docs/agents/orchestration.md`) states the rule once: a fresh
  orchestrator at any row starts its unit's budget at three whatever notes earlier
  invocations left, an agent resumed with its context keeps its own count, and the epic
  orchestrator derives its count from the notes as below. The sentence naming the epic row
  as the exception goes. One sentence gives the why, the bound a person wants is per
  invocation, citing this spec's bead. No ADR: the rule is a doc edit away from reversal,
  and ADR 0014's one-loop rule is sharpened, not overturned.
- **The epic row** (`docs/agents/orchestration.md`) says "three such fix-ups per story
  per invocation".
- **Step 6, notes.** The first review of a story in an invocation writes `epic review 1:
  <tip SHA> <verdict line>`, and `<k>` on both `epic review <k>` and `epic fix-up <k>`
  counts this invocation's reviews and fix-up rounds of that story. A story's spent budget
  is the number of `epic fix-up` notes after its last `epic review 1` note; nothing is
  held in context. The budget sentence says so in place of "counted from its `epic fix-up`
  notes".
- **Step 6, the review set.** The clause "One with three `epic fix-up` notes whose last
  `epic review` is blocking on that tip is failed and not reviewed again" is deleted. The
  `ready:` skip and the clean-with-checks-pending re-poll stay. The set's bounds stay:
  only open stories with an open PR, and a closed story or a landed or closed PR is left
  out, so a failed story is revived only while its PR is an open draft.
- **Step 6, the fourth round.** Unchanged: file nothing, leave the draft, report the
  `failed:` line. The failed story's tickets are all closed and it has a `pr:` note, so
  step 3 reads it as finished and step 5 does not spawn it; step 6 of the next invocation
  reviews its unchanged tip against the current spec. The alternative, a fourth round that
  files its tickets, would make a failed story startable with no review between
  invocations and drive stale work after a spec change.
- **Step 7, Stall.** For each story whose epic review failed this invocation, one line in
  the existing `human:` shape after its `failed:` line: `human:   <owner repo> <story-id>
  <pr url>: amend the spec and type <resume command> for three more rounds, or close the
  PR to drop the story`, the url from the story's `pr:` note and the resume command as
  Human stop prints it. The report template and the `review:` line's `fix-up <k> of 3`
  are otherwise unchanged.
- **Harness doc.** Unchanged. The epic orchestrator's continuation after a session limit
  is already "from the user's next message", and this spec names that the same
  invocation.
- **Nothing automatic grants rounds.** Only a typed command starts an invocation. A person
  wrapping the command in `/loop` makes it unbounded by their own choice under ADR 0009;
  the docs say nothing about it.
- **Version.** Bump `.claude-plugin/plugin.json` on merge, as every change does.

## Testing Decisions

- One seam: `make ci`, the skill-doc lint (`scripts/lint-skill-docs.sh`,
  `scripts/implement-spec-pins.tsv`) and its regression test
  (`scripts/test-lint-skill-docs.sh`). Each new rule is a `has` pin proven by a case that
  drops the line and expects the lint to fail; each dropped rule is a `lacks` pin proven
  the same way.
- Pins replaced in the Check gate: "the fresh budget holds at the ticket and story rows"
  and "the epic row counts from its epic fix-up notes" (dev-94a) become "a fresh
  orchestrator at any row starts at three", "the epic orchestrator counts from the notes
  after this invocation's `epic review 1`", and a `lacks` on "The epic row is the
  exception". "a resumed agent keeps its own count" and "neither row records spent
  fix-ups" stay, the latter reworded if its sentence moves.
- Pins replaced in the implement-spec skill: "a spent budget is not reviewed again" (`is
  failed and not reviewed again`) becomes a `lacks`; new `has` pins for the `epic review 1`
  delimiter, the per-invocation `<k>`, and the Stall `human:` line's two exits. "fix-up
  budget three per story", "fix-up budget's fourth" and "every fix-up round spends the
  budget" stay.
- The glossary lint covers the new entry and its `_Avoid_` list; the sweep of "run" to
  "invocation" is checked by reading, not by a pin.
- Not tested here: a live fixture run of the epic orchestrator. The next feature that
  fails an epic review exercises the revival; `/dev:retro` catches what the pins miss.

## Out of Scope

- Any bound across invocations, or a run marker note to carry one.
- `/loop` around the command.
- The ticket and story rows, whose per-invocation budget dev-94a already set.
- Reopening a closed story or a closed PR, or changing the review set's bounds.
- An ADR.

## Further Notes

The `epic review 1` delimiter is what makes the count safe on a fresh invocation: an
orchestrator that read "epic fix-up 3" from an earlier invocation as spent budget would
refuse the story before its first review, which is today's behaviour under another name.
Counting only the notes after the delimiter the invocation itself writes means no rule of
the form "when in doubt, read the notes" is needed, and the harness doc's "the beads and
notes are the truth" holds for the epic row too.

The one failure mode left is a continuation that lost its place in step 6 after a
compaction and writes a second `epic review 1` for a story it had already reviewed, which
resets that story to three. That errs toward more rounds inside the same invocation, and
the person reads it in the report's `<k>`.
