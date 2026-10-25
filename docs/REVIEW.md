# Review stages (sequence diagrams)

How a change is reviewed on its way from a ticket to a merged PR, drawn as two sequence
diagrams. This page explains; it decides nothing. The rules it draws are in
`docs/agents/orchestration.md` (Complexity tier, Review), the ticket runner brief and step
7 of `skills/implement-story/SKILL.md`, and the why in `docs/adr/0001-two-stage-review.md`.
When the diagrams and those texts disagree, the texts win and the diagram is the bug. Bold
terms are defined in `GLOSSARY.md`.

Two review tools, two stages: per ticket, the built-in `code-review` (a bug hunt at effort
`medium` or `high`, matching the tier) run by a reviewer at the tier's review model; per
story, `mattpocock-skills:code-review` (repo standards and fidelity to the spec), its two
sub-agents at the story tier's review model. Never write the review skill bare in a doc:
four skills answer to that name.

## Stage 1: per-ticket review

Runner brief steps 2 to 5, for `medium` and `high` tickets. A `low` ticket has no
reviewer: its implementer reports, and the **ticket runner** goes straight to the merger.

```mermaid
sequenceDiagram
    autonumber
    participant R as Ticket runner (opus)
    participant I as Implementer (impl model)
    participant V as Reviewer (review model, one tier up)
    participant F as Fix-up implementer (impl model, same worktree)
    participant M as Merger (impl model)
    participant BD as bd -C owner
    participant IN as Inbox (plain bd, home)

    R->>BD: update ticket --claim, read the complexity tier
    R->>I: spawn in a worktree (brief: tdd, trailers, TMPDIR line)
    I->>I: reset onto the branch tip, red-green, commit, merge the branch tip
    I-->>R: "ready for review" (branch, worktree path)
    Note over I: done, never messaged again

    loop up to three blocking rounds
        R->>V: spawn, call the built-in code-review (effort = tier), standards sources spelled out
        V-->>R: findings tagged blocking or minor, last line verdict clean or blocking (n)
        R->>BD: note ticket "review n" with the findings and the verdict line
        alt verdict blocking
            R->>F: spawn a fresh fix-up pointed at that note, no isolation
            F->>F: fix, test, commit, merge the branch tip
            F-->>R: report
        else verdict clean (minors or none)
            Note over R: no reviewer runs again
        end
    end

    alt third verdict blocking
        R-->>R: report "ticket failed" with the reason
    else clean
        opt minors in scope
            R->>F: one last fix-up for the minors (unreviewed)
            F-->>R: report
        end
        opt minors out of scope
            R->>IN: capture a retro item (needs-triage), never a bead of the story
        end
        R->>M: spawn the merger
        M->>M: merge the branch tip into the ticket branch, test
        M->>M: wait on the owner's index.lock, stray-commit check
        M->>M: merge into the integration branch, retest
        alt passing needs code changes
            M-->>R: report the changes needed
            R->>F: fresh fix-up, then merge again
        else merged
            M-->>R: merged
        end
        R->>BD: close ticket
        R-->>R: report "ticket closed"
    end
```

## Stage 2: story review and delivery

Steps 7 and 8 of `/dev:implement-story`, then the human on the forge (the runbook's
stage 5).

```mermaid
sequenceDiagram
    autonumber
    participant O as Story orchestrator (opus)
    participant BD as bd -C owner
    participant CR as mattpocock-skills code-review
    participant S as Standards sub-agent (review model)
    participant P as Spec sub-agent (review model)
    participant F as Fix-up implementer (impl model, fixup worktree)
    participant M as Merger (impl model)
    participant IN as Inbox (plain bd, home)
    participant H as Human (forge)

    O->>BD: read the story's notes (branch, review, pr)
    O->>O: git rev-parse the integration branch tip

    alt review marker equals the tip SHA
        Note over O: already reviewed, skip to the seams
    else no marker, or the tip has moved
        O->>CR: Skill call on the owner repo (diff and log against the default branch, standards paths, spec = story + tickets + Jira epic)
        par two axes at the story tier's review model
            CR->>S: repo standards plus the plugin's coding-standards.md
            S-->>CR: findings, verdict line
        and
            CR->>P: fidelity to the story, its tickets and the epic
            P-->>CR: findings, verdict line
        end
        CR-->>O: both reports (findings only, no beads)
        Note over O: one round, never fails on the verdict

        alt findings to fix (blocking and minor alike)
            O->>F: spawn the fix-up with the findings as its pointer
            F->>F: fix, test, commit (Bead = story, Refs = epic)
            F-->>O: report, unfixable items listed
            O->>M: spawn the merger (ticket brief step 4)
            M-->>O: merged
        end
        opt deferred findings (out of scope, follow-up)
            O->>IN: capture a retro item, never a child of the story
        end
        O->>BD: note story "review" with the new tip SHA
    end

    O->>O: run the test seams on the tip (read-only, timeout 600000)
    alt seams red
        O->>F: fix-up (spawned here if the marker skipped the review)
        F-->>O: report
        O->>M: merger
        M-->>O: merged
        O->>O: rerun the seams, marker unchanged (a seam fix is unreviewed)
        Note over O: a second red run skips delivery and reports "failed seam"
    end

    O->>O: stray-commit check on default branch..integration branch
    O->>H: push the branch, write the PR body (mattpocock-skills pr), mark it ready
    O->>BD: note story "pr" with the URL
    Note over O,BD: the story bead stays open
    H->>H: review and merge the PR (nothing typed)
    H->>O: /dev:close-story story-id
```

## Three rules the diagrams encode

- **One tier up, always.** The reviewer runs at the review model of the ticket's or
  story's tier, never at the implementer's. That is why the runner spawns the reviewer
  instead of letting the implementer call the skill (ADR 0001).
- **Fresh fix-up, same worktree.** Findings never go back to the first implementer by
  message. Each round spawns a new **fix-up implementer** in the worktree the implementer
  left behind (the rules doc's Orchestrator role).
- **Only blocking rounds count.** A clean round with minors ends the review loop. The
  minors get one unreviewed fix-up or go to the inbox as a **deferred finding**, and the story
  tier never fails on a verdict at all (the rules doc's Review verdict).
